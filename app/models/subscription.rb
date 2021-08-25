class Subscription < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  include StripeConcern

  CREDIT_CARD = "CreditCard"
  CHECK = "Check"
  WIRE = "Wire"
  MONTHLY = "monthly"
  YEARLY = "yearly"

  STATES = [
    [PENDING=0,"Pending"],
    [CURRENT=1,"Current"],
    [CANCELED=2,"Canceled"],
    [PAST_DUE=3,"Past Due"]
  ]

  FEATURE_PACKAGE_MATRIX = {
    recognition: [:bronze, :silver],
    nomination: [:silver],
    tasks: [:silver],
    anniversary: [:anniversary, :bronze, :silver],
    tags: [:bronze, :silver],
    leaderboards: [:bronze, :silver],
    teams: [:bronze, :silver],
    manager: [:silver],
    hall_of_fame: [:silver],
    gift_cards: [:anniversary, :silver],
    approvals: [:silver]
  }.freeze

  PRICE_PACKAGES = {
      anniversary: "Anniversary",
      bronze: "Bronze",
      silver: "Silver",
      null: "Gold",
  }.freeze

  acts_as_paranoid

  belongs_to :user, optional: true
  belongs_to :company
  belongs_to :plan, optional: true
  has_many :line_items, inverse_of: :subscription, dependent: :destroy

  before_validation :set_quantity, on: :create
  before_validation :set_company_on_line_items
  before_validation :set_sign_date

  validates :charge_interval, presence: true
  validates :amount, presence: true
  validates :quantity, presence: true, on: :create
  validates :billing_start_date, presence: true, unless: ->{credit_card?}
  validates :contract_signature, :sign_date, presence: true, if: :should_validate_signature?
  validates :user_count, numericality: { only_integer: true, greater_than: 0 }, if: :should_validate_user_count?

  attr_accessor :stripe_card_token, :skip_signature_validation, :skip_user_count_validation

  accepts_nested_attributes_for :line_items

  scope :canceled, -> { where(status: CANCELED) }
  scope :active, -> { where(status: [PENDING, CURRENT]) }
  scope :current, -> { where(status: CURRENT) }

  def self.feature_package_matrix
    FEATURE_PACKAGE_MATRIX
  end

  def self.all_packages
    PRICE_PACKAGES
  end

  def self.valid_price_package_values
    all_packages.map { |key, _value| key == :null ? nil : key.to_s }
  end

  def self.feature_permitted?(company, user, feature, skip_user_check: false)
    return false if company.blank? || (user.blank? && !skip_user_check) # company and user will be nil if logged out
    return true if company.price_package.blank?

    company_pricing_package = company.price_package.to_sym
    feature_package_matrix[feature.to_sym].include?(company_pricing_package.to_sym)
  end

  def self.mrr_total
    total = 0
    Subscription.current.includes(:plan).each do |s|
      next if s.cancelled?
      if s.monthly?
        total += s.recurring_cost
      else
        total += (s.recurring_cost / 12.0)
      end
    end
    return total
  end

  def self.yrr_total
    mrr_total * 12
  end

  def billing_label
    super || "#{company.name} subscription #{recurring_label}"
  end

  def recurring_label
    "$#{number_with_precision(amount, precision: 2)} / #{charge_interval_noun.downcase} "
  end

  def status_label
    STATES.detect{|state| state[0] == status}[1]
  end

  def total_with_unbilled_line_items
    total = self.amount
    self.line_items.unbilled.inject(total){|sum, item| sum + item.amount}
  end

  def cancel!
    update_column(:status, CANCELED)
  end

  def cancelled?
    self.status == CANCELED
  end

  def purchased?
    self.status == CURRENT
  end

  def pending?
    self.status == PENDING
  end

  def customer
    stripe_customer
  end

  def charge_interval_adverb
    charge_interval.present? ? charge_interval.downcase : (plan.present? ? plan.interval_adverb.downcase : 'Not set')
  end

  def monthly?
    charge_interval_adverb == MONTHLY
  end

  def yearly?
    charge_interval_adverb == YEARLY
  end

  def charge_interval_noun
    charge_interval_adverb.gsub(/ly$/,'')
  end

  def credit_card?
    payment_method == CREDIT_CARD
  end

  def check?
    payment_method == CHECK
  end

  def wire?
    payment_method == WIRE
  end

  def next_invoice
    next_stripe_invoice
  end

  def invoices
    if stripe_customer_token.present?
      stripe_invoices
    else
      []
    end
  end

  def recurring_cost
    if self.amount.present?
      self.amount
    else
      self.unit_price * (self.quantity || self.company.users.count) rescue 0
    end
  end

  def calculate_unit_price
    if self.valid_coupon?
      self.plan.unit_price * (self.coupon.percent_off / 100.0)
    else
      self.plan.unit_price
    end
  end

  def unit_price
    super || calculate_unit_price
  end

  def apply_promotion(coupon)
    self.coupon_code = coupon.try(:code)
  end

  def save_with_payment!
    if valid?
      self.unit_price = self.calculate_unit_price # plan is not set when subscription is invalid
      opts = {
        email: self.email,
        # quantity: user_count,
        plan: plan.name,
        card: stripe_card_token,
      }

      transaction do
        # create customer
        raise Stripe::StripeError.new("Missing card token") if opts[:card].blank?

        customer = Stripe::Customer.create(opts.except(:plan).merge({description: "Customer for #{self.company.domain}"}))

        # create line items
        items = LineItem.create_invoice_items_for_customer!(self, customer)

        # create subscription
        subscription_opts = {plan: plan.name}
        subscription_opts[:coupon] = self.coupon_code if self.coupon_code.present?
        customer.subscriptions.create(subscription_opts) unless customer.subscriptions.total_count > 0

        # save local subscription
        self.stripe_customer_token = customer.id
        self.status = CURRENT
        save!
        notify_admin
        self.company.enable_admin_dashboard!

      end
    end
    return true

  # Note: Sequence of these rescue blocks is important, because Stripe::StripeError is the base class
  # of other specific stripe errors and thus it should only be rescued in the end
  rescue Stripe::InvalidRequestError, Stripe::CardError => e
    logger.error "Stripe error while creating customer: #{e.message}"
    ExceptionNotifier.notify_exception(e, data: {email: self.email, company: self.company.domain})
    errors.add :base, I18n.t("activerecord.errors.models.subscription.problem_cc", message: e.message)
    false
  rescue Stripe::StripeError => e
    logger.error "Stripe error: #{e.message}"
    ExceptionNotifier.notify_exception(e, data: {email: self.email, company: self.company.domain})
    errors.add :base, I18n.t("activerecord.errors.models.subscription.validate_cc")
    false
  end

  def update_card!(params)
    params = {} unless params.present?
    stripe_customer = Stripe::Customer.retrieve(stripe_customer_token)
    cards_to_delete = stripe_customer.sources.data.map(&:id)
    stripe_customer.sources.create(card: params[:stripe_card_token])
    cards_to_delete.each{|card_id| stripe_customer.sources.retrieve(card_id).delete }
    return true
  rescue Stripe::InvalidRequestError, Stripe::CardError => e
    logger.error "Stripe error while creating customer: #{e.message}"
    errors.add :base, I18n.t("activerecord.errors.models.subscription.problem_cc", message: e.message)
    false
  end

  def valid_coupon?
    self.coupon.try(:valid_for_use?)
  end

  def coupon
    @coupon ||= Coupon.find_or_sync(self.coupon_code)
  end

  protected

  def notify_admin
    SystemNotifier.delay(queue: 'priority').new_subscription(self.id)
  end

  def set_sign_date
    if contract_signature_added?
      self.sign_date = Date.today
    end
  end

  def contract_signature_added?
    changes[:contract_signature] &&
    changes[:contract_signature][0].nil? && #previous value
    changes[:contract_signature][1].present? # current value
  end

  def set_quantity
    self.quantity = 1
  end

  def set_company_on_line_items
    self.line_items.each do |item|
      item.company_id = self.company_id
    end
  end

  def should_validate_signature?
    if skip_signature_validation.present?
      return false
    else
      contract_body.present?
    end
  end

  # This is validated for the end-user Upgrade form
  # but not for the site admin form (as there is no user_count field there)
  def should_validate_user_count?
    !skip_user_count_validation
  end
end
