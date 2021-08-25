module Rewards
  class FundsTxn < ApplicationRecord
    belongs_to :funds_account, optional: true
    belongs_to :funds_txnable, polymorphic: true, optional: true
    belongs_to :catalog, optional: true

    # Current polymorphic associations are StripeCharge, FundsAccountManualAdjustment
    # Tango redemptions should also have a polymorphic association here

    validates_inclusion_of :amount_currency_code, in: Rewards::Currency.supported_currencies_iso_codes
    validates_inclusion_of :txn_type, in: ['credit', 'debit'], message: "%{value} is not valid.  It must be either credit or debit"
    validates :description, presence: true

    scope :not_admin_acct, -> { joins(:funds_account).where.not(funds_accounts: {recognize_admin: true}) }
    scope :credit, -> { where(txn_type: "credit") }
    scope :debit, -> { where(txn_type: "debit") }
    scope :redemption, -> { where(funds_txnable_type: "redemption") }

    def credit?
      txn_type.to_sym == :credit
    end

    def debit?
      txn_type.to_sym == :debit
    end

  end
end
