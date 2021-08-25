module Rewards
  class FundsAccount < ApplicationRecord
    has_many :funds_txns, dependent: :destroy
    belongs_to :company, optional: true

    scope :recognize_admin_accts, -> { where(recognize_admin: true) }
    scope :primary, ->{ where(recognize_admin: false, is_primary: true).limit(1) }

    validates :company_id, presence: true
    validates_inclusion_of :currency_code, in: Rewards::Currency.supported_currencies_iso_codes

    validate :only_one_primary

    def service_charge
      0 # stub, no service charges for now
    end

    def service_charge?
      service_charge > 0
    end

    # Credit a funds_account
    # takes an object that has a polymorphic relation to funds_txnable
    # and has an amount field that specifies the amount to
    # credit to the account
    #
    # This method will credit the account and log the transaction
    # to funds_txn
    #

    def credit(txnable)
      # Make sure to lock the row (select for update) before checking the balance
      # with_lock does a reload, so it ensures we are up to date
      self.with_lock do
        new_balance = self.balance + txnable.amount
        adjust_balance("credit", new_balance, txnable)
      end
    end

    # Debit a funds_account
    # takes an object that has a polymorphic relation to funds_txnable
    # and has an amount field that specifies the amount to
    # debit to the account
    #
    # This method will debit the account and log the transaction
    # to funds_txn
    #
    def debit(txnable)
      # Make sure to lock the row (select for update) before checking the balance
      # with_lock does a reload, so it ensures we are up to date
      self.with_lock do
        new_balance = self.balance - txnable.amount
        adjust_balance("debit", new_balance, txnable)
      end
    end

    def recalculate_balance!
      credits, debits = self.funds_txns.partition{|t| t.txn_type == 'credit' }
      credit_total = credits.sum(&:amount)
      debit_total = debits.sum(&:amount)
      self.update_column(:balance, credit_total - debit_total)
    end

    private

    # Helper method to log a journal entry to funds_txn then update
    # account balance.
    #
    # NOTE!!!  It assumes a transaction has already been established
    #          by the caller.
    #
    def adjust_balance(txn_type, new_balance, txnable)

      txn = FundsTxn.create!(
        txn_type: txn_type,
        amount: txnable.amount,
        amount_currency_code: txnable.amount_currency_code,
        catalog_id: txnable.respond_to?(:catalog) ? txnable.catalog.id : nil,
        resulting_balance: new_balance,
        funds_txnable_id: txnable.id,
        funds_txnable_type: txnable.class.name,
        description: txnable.try(:description) || txnable.try(:comment) || txnable.try(:label),
        funds_account: self)
      self.balance = new_balance
      self.save!
    end

    def only_one_primary
      if self.is_primary?
        existing_primary = Rewards::FundsAccount.primary.where(company_id: self.company_id)
        existing_primary = existing_primary.where.not(id: self.id) if self.persisted?
        if existing_primary.exists?
          errors.add(:is_primary, "is only allowed to be set for one account at a time.")
          return false
        end
      end
    end
  end
end
