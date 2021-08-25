module Rewards
  class FundsAccountManualAdjustment < ApplicationRecord
    has_many :funds_txns, as: :funds_txnable, dependent: :destroy

    def amount_currency_code
      # TODO: implement multi-currency adjustments
      'USD'
    end    
  end
end
