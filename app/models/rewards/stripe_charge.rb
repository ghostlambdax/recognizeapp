module Rewards
  class StripeCharge < ApplicationRecord

    belongs_to :user_stripe_customer, optional: true

    has_many :funds_txns, as: :funds_txnable, dependent: :destroy

    validates_presence_of :amount
    validates_presence_of :stripe_charge_id

    def amount_currency_code
      # TODO: implement multi-currency stripe transactions
      'USD'
    end

    def description
      "Credit card deposit"
    end
  end
end
