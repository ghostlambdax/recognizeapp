module Rewards
  class MoneyDepositer
    include ActiveModel::Model
    # FIXME: this is a quirk of rails v4, probably can remove this when moving to rails v5
    include ActiveModel::Validations::Callbacks 
    include Rails.application.routes.url_helpers

    attr_accessor :company, :amount, :funding_source_id, :comment, :catalog, :form_id

    before_validation :cast_funding_source_id

    validate :form_id_is_unique
    validates :company, :amount, :funding_source_id, :comment, presence: true
    validates :amount, numericality: {greater_than: 0}, allow_blank: true
    validates :funding_source_id, inclusion: {in: Rewards::FundingSources.all.map(&:id)}, allow_blank: true

    def account
      company.primary_funding_account
    end

    def attributes
      {
        amount: self.amount,
        funding_source_id: self.funding_source_id
      }
    end

    def balance
      calculator.reward_monetary_balance
    end

    def balance_currency
      calculator.reward_monetary_balance_currency
    end

    def calculator
      @catalog ||= company.principal_catalog
      @calculator ||= Rewards::RewardPointCalculator.new(company, @catalog)
    end

    def deposit!
      if valid?

        case funding_source_id
        when Rewards::FundingSources::MANUAL
          FundsAccountService.manual_credit(account, amount, comment)

        when Rewards::FundingSources::WIRE
          FundsAccountService.deposit_wire(account, amount, comment)

        when Rewards::FundingSources::CHECK
          FundsAccountService.deposit_check(account, amount, comment)

        when Rewards::FundingSources::CREDIT
          raise "Credit cards are not supported through this form"

        else
          raise "Unsupported funding source id"
        end
        @deposited = true
        cache_form_id
      end
    end

    def deposited?
      !!@deposited
    end

    def persisted?
      deposited?
    end

    private
    def cast_funding_source_id
      if funding_source_id.present?
        self.funding_source_id = self.funding_source_id.to_i
      end
    end

    def form_id_is_unique
      if duplicate_form_submission?(self.form_id)
        errors.add(:base, I18n.t('forms.duplicate_submission'))
      end
    end

    def duplicate_form_submission?(id)
      return false unless id

      request_key = get_cache_key(id)
      Rails.logger.info("Fetching from cache: #{request_key}")
      if Rails.cache.exist?(request_key)
        Rails.logger.warn('*** Caught duplicate request ***')
        return true
      end

      false
    end

    def cache_form_id
      return unless self.form_id
      request_key = get_cache_key(self.form_id)

      Rails.logger.info("Writing to cache: #{request_key}")
      Rails.cache.write(request_key, true, expires_in: 15.minutes)
    end

    def get_cache_key(id)
      "Rewards::MoneyDepositer-form-id:#{id}"
    end
  end
end
