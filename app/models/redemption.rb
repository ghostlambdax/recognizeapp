class Redemption < ApplicationRecord
  include Wisper::Publisher
  include ClaimPresenterConcern

  enable_duplicate_request_preventer

  LOW_REWARD_BALANCE_THRESHOLD = 250

  acts_as_paranoid

  belongs_to :reward, inverse_of: :redemptions
  belongs_to :reward_variant, inverse_of: :redemptions, class_name: "Rewards::RewardVariant"
  belongs_to :user, inverse_of: :redemptions
  belongs_to :company, inverse_of: :redemptions
  has_many :point_activities, ->{ PointActivity.redemptions }, foreign_key: :activity_object_id, dependent: :destroy
  has_many :funds_txns, as: :funds_txnable, class_name: "Rewards::FundsTxn"
  belongs_to :approver, :class_name => "User", optional: true
  belongs_to :denier, :class_name => "User", optional: true

  before_validation :ensure_company_id

  validates :reward_id, :user_id, :company_id, :points_at_redemption_time, :points_redeemed, :value_redeemed, :reward_variant_id, presence: true
  validates :points_at_redemption_time, numericality: {only_integer: true, greater_than: 0}, allow_blank: true
  validate :reward_matches_company
  validate :reward_is_enabled
  validate :reward_variant_is_enabled
  validate :user_has_enough_points, on: :create
  validate :is_within_interval, on: :create
  validate :is_within_quantity, on: :create
  validate :cannot_approve_your_own_redemption
  validate :provider_reward_redemption_cannot_have_additional_instructions

  before_commit :handle_redemptions_bound_to_be_auto_approved, on: :create
  after_commit :send_notifications, on: :create

  scope :managed_by, ->(user) { joins(:reward).where(rewards: {manager_id: user.id})}
  scope :by_catalog, ->(catalog) { joins(:reward).where(rewards: {catalog: catalog}) }
  scope :approved_or_pending, ->{ where(status: [:approved, :pending]) }
  scope :approved, ->{ where(status: :approved) }
  scope :unapproved, ->{ where(status: [nil, :pending]) }
  scope :not_denied, -> { where.not(status: :denied) }

  def self.redeem(user, variant, opts = {})

    redemption = Redemption.new do |r|
      r.user = user
      r.reward = variant.reward
      r.company = user.company
      r.reward_variant = variant
      r.points_at_redemption_time = user.redeemable_points
      r.points_redeemed = variant.points
      r.value_redeemed = variant.face_value
      # only for the provider reward redeemed currency needs to be stored
      r.value_redeemed_currency_code = variant.reward.catalog.currency if variant.reward.provider_reward?
      r.viewer = opts[:viewer]
      r.viewer_description = opts[:viewer_description]
    end

    begin
      redemption.save
    rescue => e
      ExceptionNotifier.notify_exception(e, data: {user: user.id, reward: variant.reward.id, variant: variant.id})
      redemption.errors.add(:base, "There was an error redeeming. Please contact support. Error code: #{Time.now.to_f.to_s}")
    end

    return redemption
  end

  def reverse!
    raise "Can't reverse provider fulfilled rewards" if self.reward.provider_reward?
    self.destroy
    self.user.update_all_points!
  end

  # amount is the value redeemed converted to base currency(i.e usd)
  # which is used for the internal accounting of funds
  #
  # This method will return
  # value_redeemed_in_usd if present
  # value_redeemed if value_redeemed_currency_code is blank or equal to base currency
  # value_redeemed converted to base currency if all above condition fail
  def amount
    return value_redeemed_in_usd if value_redeemed_in_usd
    base_currency = Rewards::Currency::RECOGNIZE_BASE_CURRENCY
    return value_redeemed if value_redeemed_currency_code.blank? || value_redeemed_currency_code == base_currency
    Money.from_amount(value_redeemed, value_redeemed_currency_code).exchange_to(base_currency).to_f
  end

  def amount_currency_code
    value_redeemed_currency_code
  end

  def catalog
    reward.catalog
  end

  def check_not_resolved_already
    return if new_record?

    # In the past, duplicate redemptions were encountered, which were probably due to race conditions where there was a
    # state mismatch between runtime instance of redemption vs database instance of redemption. Therefore, check the
    # status against the state in db.
    self_in_db = Redemption.find(self.id)
    if self_in_db.approved?
      errors.add(:base, I18n.t('activerecord.errors.models.redemption.already_approved'))
    elsif self_in_db.denied?
      errors.add(:base, I18n.t('activerecord.errors.models.redemption.already_denied'))
    end
  end

  def approve(approver:, additional_instructions: nil, request_form_id: nil)
    check_not_resolved_already
    return false if errors.present?

    result = nil

    self.with_lock do
      # mark as approved so we get approval validations
      self.status = :approved
      self.approver = approver
      self.additional_instructions = additional_instructions.presence
      self.request_form_id = request_form_id if request_form_id

      if valid?
        result = if self.reward.provider_reward.present?
                   approve_provider_reward(approver)
                 else
                   approve_company_managed_reward(approver)
                 end
        if result
          RedemptionNotifier.delay(queue: 'priority').notify_status_approved(self.user, self)
          self.delay(queue: 'priority').publish(:redemption_approved, self)
        end
      else
        result = false
      end
    end

    return result
  end

  def deny(denier: )
    check_not_resolved_already
    return false if errors.present?

    result = nil

    self.with_lock do
      self.status = :denied
      self.denier_id = denier.id
      self.denied_at = Time.now
      PointActivity::Recorder::RedemptionDenialRecorder.record!(self)
      result = self.save
      self.delay(queue: 'priority').publish(:redemption_denied, self) if result
    end
    # Commenting this out for now. Most people probably want to handle a denied redemption
    # personally. However, one day we should parametize this so an admin can choose
    # and possibly customize the notification.
    # RedemptionNotifier.delay.notify_status_denied(self.user, self) if result
    return result
  end

  def auto_approved?
    approved? && approver_id == auto_approver.id
  end

  def approved?
    self.status.to_sym == :approved
  end

  def denied?
    self.status.to_sym == :denied
  end

  def pending?
    self.status.to_sym == :pending
  end

  def description
    I18n.t('rewards.admin_email_header', name: user.full_name, reward_title: reward_label)
  end

  def reward_label
    # FIXME: put this in a helper
    if reward.provider_reward?
      formatted_value = Rewards::Currency.currency_prefix(value_redeemed_currency_code)
      formatted_value << value_redeemed.to_s.no_zeros
      "#{self.reward.title} #{formatted_value}"
    else
      self.reward.title
    end
  end

  def summary_label
    "#{self.user.full_name} redeemed #{reward_label}"
  end

  private

  def provider_reward_redemption_cannot_have_additional_instructions
    if self.reward.provider_reward? && self.additional_instructions.present?
      self.errors.add(:base, I18n.t("activerecord.errors.models.redemption.provider_reward_redemption_cannot_have_additional_instructions"))
    end
  end

  def approve_company_managed_reward(approver)
    raise "Should not call this method because its not a company managed reward" if self.reward.provider_reward.present?

    self.status = :approved
    self.approver = approver
    self.approved_at = DateTime.now
    self.save
  end

  def approve_provider_reward(approver)
    raise "Should not call this method because its not a provider reward" unless self.reward.provider_reward.present?

    # find the user's company funds account
    account = company.primary_funding_account
    # make sure the account can afford the amount requests
    if account.balance < self.amount
      self.errors.add(:base, "Your redemption funds account balance is too low. Please contact support.")
      return false
    end

    # attempt to charge for the redemption
    begin
      Redemption.transaction(requires_new: true) do
        result = Rewards::RewardService.process_provider_redemption(self)
        if result[:success]
          amount_charged = result[:amount_charged]

          if (amount_charged)
            self.value_redeemed_in_usd = amount_charged[:total]
            self.value_redeemed_exchange_rate = amount_charged[:exchange_rate]
          end

          Rewards::FundsAccountService.redemption(account, self)
          self.approved_at = DateTime.now
          self.response_message = result[:response]
          self.save!
          if (account.balance <= Redemption.low_reward_balance_threshold(approver.company))
            SystemNotifier.delay(queue: 'priority').low_reward_balance(account)
          end
        else
          self.update_column(:response_message, result[:response])
          self.errors.add(:response_message, result[:response])
          raise ActiveRecord::RecordInvalid, self
        end
      end
    rescue ActiveRecord::RecordInvalid => e
    end
    return self.errors.count == 0
  end

  def cannot_approve_your_own_redemption
    return unless approved?
    return if bound_to_be_auto_approved?

    if (approver.id == user.id)
    # or rather, if approving...
      errors.add(:base, I18n.t('activerecord.errors.models.redemption.cannot_approve_own_redemption'))
    end
  end

  def ensure_company_id
    self.company_id = self.user.company_id if self.user.present?
  end

  def reward_matches_company
    if reward && reward.company_id != self.company_id
      errors.add(:base, I18n.t('activerecord.errors.models.redemption.reward_matches_company', default: 'Reward does not appear to offered by your company'))
    end
  end

  def reward_is_enabled
    return if denied?

    if reward && !reward.enabled?
      errors.add(:base, I18n.t('activerecord.errors.models.redemption.reward_is_enabled', default: 'Reward is not currently active and may not be redeemed'))
    end
  end

  def reward_variant_is_enabled
    return if denied?

    unless self.reward_variant.is_enabled?
      self.errors.add(:base, I18n.t('activerecord.errors.models.redemption.reward_variant_is_enabled', default: "Reward variant is not currently active and may not be redeemed."))
    end
  end


  def user_has_enough_points
    if user && !reward.can_redeem_by_points?(user, self.reward_variant)
      errors.add(:base, I18n.t('activerecord.errors.models.redemption.not_enough_points', default: 'Reward may not be redeemed because user does not have enough points'))
    end
  end

  def is_within_interval
    # only check this when the redemption is new
    if self.id.blank? and !reward.can_redeem_within_frequency?(user)
      errors.add(:base, I18n.t('activerecord.errors.models.redemption.is_within_interval', default: 'Reward has already been redeemed recently. Check back soon to see if you can redeem it.'))
    end
  end

  def is_within_quantity
    # only check this when the redemption is new
    if self.id.blank? and !reward.can_redeem_within_quantity?(self.reward_variant)
      errors.add(:base, I18n.t('activerecord.errors.models.redemption.is_within_quantity', default: 'Reward has already been redeemed recently. Check back soon to see if you can redeem it.'))
    end
  end

  def send_notifications
    RedemptionNotifier.delay(queue: 'priority').notify_of_redemption(user, self) unless auto_approved?
    RedemptionNotifier.delay(queue: 'priority').notify_admin_of_redemption(user, self)
    self.delay(queue: 'priority').publish(:redemption_pending, self) unless auto_approved?
  end

  def self.low_reward_balance_threshold(company)
    company.settings.low_balance_threshold || LOW_REWARD_BALANCE_THRESHOLD
  end

  def bound_to_be_auto_approved?
    reward.provider_reward? &&
      !company.require_approval_for_provider_reward_redemptions?
  end

  def handle_redemptions_bound_to_be_auto_approved
    return unless bound_to_be_auto_approved?
    return if approved?

    approve(approver: auto_approver, additional_instructions: nil)
  end

  def auto_approver
    User.system_user
  end
end
