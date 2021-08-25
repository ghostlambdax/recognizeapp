class Catalog < ApplicationRecord
  include Authz::PermissionsHelper

  belongs_to :company
  has_many :rewards, inverse_of: :catalog
  has_many :redemptions, through: :rewards
  has_many :reward_variants, through: :rewards, source: :variants do
    def company_fulfilled
      where('rewards.provider_reward_id is NULL')
    end
  end

  attr_accessor :company_roles

  validate :verify_points_to_currency_ratio_change, on: :update
  validate :currency_is_unchanged, on: :update
  validates :points_to_currency_ratio, presence: true, numericality: { greater_than: 0, allow_nil: true }
  validates_presence_of :company
  validates_presence_of :currency, message: I18n.t("activerecord.errors.models.catalog.attributes.currency.blank")
  validates :currency, uniqueness: {scope: [:company_id], case_sensitive: true}
  validates_inclusion_of :currency, in: Rewards::Currency.supported_currencies_iso_codes, if: -> { errors[:currency].blank? }

  scope :enabled, -> { where(is_enabled: true) }

  def can_modify_points_to_currency_ratio?
    redemptions.unapproved.size.zero?
  end

  def currency_info
    Rewards::Currency.format_currency_prefix(currency, symbol: false, iso_code: false, name: true, name_prefix: false)
  end

  def company_roles
    @company_roles ||= roles_with_permission(:redeem)
  end

  def currency_prefix(opts={})
    Rewards::Currency.currency_prefix(currency, opts)
  end

  def label
    "#{currency_prefix} #{currency_info}"
  end

  def save_with_roles
    begin
      transaction do
        save!
        assign_roles if (company_roles.present?)
      end
      self
    rescue
      # noop
    end
  end

  def assign_roles
    new_roles = self.company.company_roles.where(id: company_roles).to_a
    grant_permission_to_roles(:redeem, new_roles)
  end

  private

  def verify_points_to_currency_ratio_change
    return unless points_to_currency_ratio_changed?
    unless can_modify_points_to_currency_ratio?
      errors.add(:points_to_currency_ratio, :pending_redemptions)
    end
  end

  def currency_is_unchanged
    errors.add(:currency, :currency_modified) if currency_changed?
  end
end
