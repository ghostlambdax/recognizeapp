# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Nuggets of wisdom with regards to rewards:
#
# + Companies have a points_to_currency_ratio which is the number of points per $1
#
# + There are essentially 3 kinds of rewards: Company Rewards, Variable amount gift cards, and discrete amount gift cards
# + All rewards will have at least one reward_variant. Reward variant is where the point amount and value amount are specified
#
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
class Reward < ApplicationRecord
  include ActionView::Helpers::UrlHelper

  acts_as_paranoid

  belongs_to :company, optional: true
  belongs_to :catalog, optional: true
  belongs_to :manager, class_name: "User", optional: true
  belongs_to :provider_reward, class_name: "Rewards::ProviderReward", optional: true

  has_many :variants, ->{ order(:face_value) }, class_name: "Rewards::RewardVariant", inverse_of: :reward, dependent: :destroy
  has_many :redemptions, inverse_of: :reward

  accepts_nested_attributes_for :variants, allow_destroy: true

  validates :title, :description, :catalog_id, presence: true
  validates :manager_id, presence: true, unless: ->{ provider_reward_id.present? }
  validates :quantity, numericality: {only_integer: true, greater_than_or_equal_to: 0}, if: ->{!quantity.nil?}
  validates :quantity_interval_id, inclusion: {in: Interval::RESET_INTERVALS_WITH_NULL.keys}
  validates :interval_id, inclusion: {in: Interval::RESET_INTERVALS_WITH_NULL.keys}
  validates :frequency, numericality: { only_integer: true, greater_than: 0, allow_blank: true}
  validates :frequency, presence: {message: I18n.t('activerecord.errors.models.reward.interval_specified')}, if: ->{interval_id.present?}

  validate :quantity_is_greater_than_number_of_redemptions
  validate :has_at_least_one_variant, on: [:create, :update]
  validate :no_duplicate_provider_rewards, if: :provider_reward?
  validate :can_not_have_variants_without_quantity, if: :has_variants_with_quantity?
  validate :cannot_enable_if_provider_reward_is_disabled, if: :enabled_changed?

  before_validation :set_quantity_from_variants

  before_update :find_or_create_reward_variant
  after_commit :sync_roles

  scope :for_company, ->(company){ where(company_id: company.id)}
  scope :enabled, ->{ where(enabled: true) }
  scope :published, ->{ where(published: true) }
  scope :managed_by, ->(user){ where(manager_id: user.id) }
  scope :company_fulfilled, ->{ where(provider_reward_id: nil) }
  scope :provider_fulfilled, ->{ where.not(provider_reward_id: nil) }
  scope :from_active_catalogs, -> { joins(:catalog).where(catalogs: { is_enabled: true }) }

  # I wish we could re-use :not_disabled scope from User.rb but couldn't really figure it out
  scope :with_not_disabled_manager, ->{ joins(:manager).where("users.status <> 'disabled'")}

  mount_uploader :image, RewardsImageUploader

  # def redeemable_by?(user)
  #   redeemable = true
  #   redeemable &&= can_redeem_within_quantity?
  #   redeemable &&= can_redeem_by_points?(user)
  #   redeemable &&= can_redeem_within_frequency?(user)
  #   return redeemable
  # end

  def self.attributes_for_json
    [:id, :title, :description, :company_id, :enabled, :url, :image]
  end

  def self.convert_points_to_currency(points, catalog)
    ratio = catalog.points_to_currency_ratio
    return nil unless points.present? && ratio.present?

    # supports ranges, arrays, and single items
    # preserves the source class
    # ratio is points per cent
    case points
    when Range
      convert_points_to_currency(points.min, catalog)..convert_points_to_currency(points.min, catalog)
    when Array
      points.map{|p| convert_points_to_currency(p, catalog) }
    else
      points.to_f / ratio.to_f
    end

  end

  def self.convert_currency_to_points(values, catalog)
    ratio = catalog.points_to_currency_ratio
    return nil unless values.present? && ratio.present?

    # supports ranges, arrays, and single items
    # preserves the source class
    # value is in whole currency, not cents
    case values
    when Range
      convert_currency_to_points(values.min, catalog)..convert_currency_to_points(values.max, catalog)
    when Array
      values.map{|v| convert_currency_to_points(v, catalog) }
    else
      values.to_f * ratio.to_f
    end

  end

  def self.redeemable_rewards(user)
    user.company.rewards.enabled.from_active_catalogs.select { |r| r.lowest_variant.points < user.redeemable_points }
  end

  def url
    Rails.application.routes.url_helpers.company_admin_reward_url(self, network: self.network, host: Recognize::Application.config.host)
  end

  def network
    @network ||= self.company.domain
  end

  def initialize_discrete_variants
    prv_set = self.provider_reward.provider_reward_variants.active.map(&:id)
    v_set = self.variants.map(&:provider_reward_variant_id)
    missing_variant_ids = prv_set - v_set
    missing_variants = self.provider_reward.provider_reward_variants.active.where(id: missing_variant_ids)
    missing_variants.each do |mv|
      self.variants.build(provider_reward_variant_id: mv.id, face_value: mv.face_value)
    end

    return missing_variants
  end

  def interval
    @interval ||= Interval.new(interval_id)
  end

  def company_fulfilled_reward?
    !provider_reward?
  end

  # fulfillment by a provider
  def provider_reward?
    self.provider_reward_id.present?
  end

  # FIX ME: denormalize this onto rewards, for better perf
  def discrete_provider_reward?
    @discrete_provider_reward ||= begin
      self.provider_reward? &&
        self.provider_reward.provider_reward_variants.active.present? &&
        self.provider_reward.provider_reward_variants.active.first.value_type == "FIXED_VALUE"
    end
  end

  # FIX ME: denormalize this onto rewards, for better perf
  def variable_provider_reward?
    @variable_provider_reward ||= begin
      self.provider_reward? &&
      self.provider_reward.provider_reward_variants.active.length == 1 &&
      self.provider_reward.provider_reward_variants.active.first.value_type == "VARIABLE_VALUE"
    end
  end

  def quantity_interval
    @quantity_interval ||= Interval.new(quantity_interval_id)
  end

  def quantity_remaining
    self.quantity && (
      self.quantity - existing_company_redemptions_count_in_interval
    )
  end

  def restricted_by_user_limit?
    frequency.present? && frequency > 0 && !interval.null?
  end

  def restricted_by_quantity?
    (!quantity.nil? && quantity > 0) && !quantity_interval.null?
  end

  def has_variants_with_quantity?
    enabled_variants = self.variants.select { |v| v.is_enabled == true }
    self.company_fulfilled_reward? && enabled_variants.detect{ |v| v.quantity.present? }.present?
  end

  def set_quantity_from_variants
    return if self.provider_reward?

    variants_with_quantity = self.variants.select{ |v| v.is_enabled == true && v.quantity.present? }

    self.quantity = if variants_with_quantity.present?
      variants_with_quantity.map(&:quantity).inject(:+)
    else
      self.quantity.presence ? self.quantity : nil
    end
  end

  def existing_user_redemptions_count_in_interval(user)
    user.redemptions.not_denied.where(reward_id: self.id).where("created_at > ?", self.interval.start).size
  end

  def existing_company_redemptions_count_in_interval
    redemptions = company.redemptions.not_denied.where(reward_id: self.id)

    if self.quantity_interval.null?
      redemptions.size
    else
      redemptions.where("created_at > ?", self.quantity_interval.start).size
    end
  end

  def can_redeem_within_frequency?(user)
    return true if self.interval_id.blank?
    existing_user_redemptions_count_in_interval(user) < self.frequency
  end

  def can_redeem_by_points?(user, variant = self.lowest_variant)
    # if no variant is passed in, see if this reward is at all redeemable
    # by checking lowest variant
    user.redeemable_points >= variant.points
  end

  def lowest_variant
    @lowest_variant ||= self.variants.enabled.min{|v| v.face_value }
  end

  def manager_with_default
    manager || self.company.company_admin
  end

  def can_redeem_within_quantity?(variant)
    return true if self.quantity.nil?
    if variant.quantity.present?
      variant.can_redeem_within_quantity?
    else
      quantity_remaining > 0
    end
  end

  def image_url
    url = if self.provider_reward?
            self.provider_reward.image_url
          else
            self.image.url
          end
    url || reward_placeholder_image
  end

  def reward_placeholder_image
    #FIXME: implement better placeholder image
    ""
  end

  def has_duplicate_provider_reward?
    return false unless provider_reward?

    q = Reward.enabled.for_company(self.company).where(provider_reward_id: self.provider_reward_id)
    q = q.where.not(id: self.id) if persisted?
    q.exists?
  end

  def can_be_enabled?
    !provider_reward? || provider_reward.active?
  end

  def cannot_enable_if_provider_reward_is_disabled
    enabled_before, enabled_now = *enabled_change
    if !enabled_before && !self.can_be_enabled?
      self.errors.add(:base, I18n.t('rewards.provider_reward_disabled'))
    end
  end

  private

  def can_not_have_variants_without_quantity
    enabled_variants = variants.select { |v| v.is_enabled == true }
    variants_without_quantity = enabled_variants.reject { |variant| variant.quantity.present? }
    return if variants_without_quantity.blank?

    self.errors.add(:variants, I18n.t("activerecord.errors.models.reward.all_variants_need_quantity_or_none_do"))
  end

  def quantity_is_greater_than_number_of_redemptions
    return if self.quantity.nil?
    if quantity_remaining < 0
      self.errors.add(:quantity, I18n.t("activerecord.errors.models.reward.greater_than_quantity_redeemed"))
    end
  end

  def has_at_least_one_variant
    return unless self.enabled?

    variants = self.discrete_provider_reward? ? self.variants.select { |v| v.provider_reward_variant&.status == "active" } : self.variants

    if variants.select { |x| x.is_enabled == true }.blank?
      self.errors.add(:base, "Reward needs at least one variant")
    end
  end

  def no_duplicate_provider_rewards
    return unless has_duplicate_provider_reward?

    message = if persisted?
                if self.enabled? && self.changes['enabled']
                  # add error if this reward is disabled & the current update enables it
                  I18n.t('rewards.duplicate_reward_cannot_enable')
                elsif self.enabled? && !self.changes['enabled']
                  # add error if this reward is active & the current update does not disable it
                  # this is for legacy rewards only, that could be affected by a bug which allowed this duplication
                  I18n.t('rewards.duplicate_reward_cannot_update')
                end
              else # new reward
                I18n.t('rewards.cannot_be_added_twice')
              end
    self.errors.add(:base, message) if message
  end

  def sync_roles
    return unless self.previous_changes.key?(:manager_id) || self.previous_changes.key?(:enabled)
    ManagerRoleSyncer.delay(queue: 'priority_caching').sync!(self.company_id)
  end

  # When a variant is removed, it is disabled by setting `is_enabled` to `false`. However, (in rare occassions) if a
  # 'new' variant with the same value as the value of the disabled one is added again, instead of adding a new record to
  # `reward_variants` table, we try to enable the disabled reward variant.
  # For more see: https://github.com/Recognize/recognize/issues/3059#issuecomment-638631194
  def find_or_create_reward_variant
    return if discrete_provider_reward?

    self.variants = self.variants.map do |variant|
      if variant.new_record?
        rv = begin
          # If there is a reward variant with the same face_value as this new one, re-enable instead of creating one.
          disabled_duplicate_variant = Rewards::RewardVariant.find_by(reward_id: self.id, face_value: variant.face_value, label: variant.label, is_enabled: false)
          new_variant = Rewards::RewardVariant.new(reward_id: self.id)
          disabled_duplicate_variant || new_variant
        end

        rv.is_enabled = variant.is_enabled
        rv.provider_reward_variant_id = variant.provider_reward_variant_id
        rv.face_value = variant.face_value
        rv.label = variant.label
        rv.quantity = variant.quantity
        rv.save
        rv
      else
        # The following conditional is to handle an edge case where, when a variant is removed (is_enabled = false)
        # and subsequently added again(i.e same face_value), in the same form submission; it disables the variant instead
        # of enabling it, against the expected behaviour. This also prevents the case where there can be a reward with
        # no variant because of the above described case. `!self.changed.include?("enabled")` is to prevent any issues
        # when the reward is being disabled/enabled.
        if variant.changed.include?("is_enabled") && !self.changed.include?("enabled")
          variant.save
        end
        variant
      end
    end
  end
end
