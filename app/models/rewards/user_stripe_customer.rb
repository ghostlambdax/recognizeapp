module Rewards
  class UserStripeCustomer < ApplicationRecord

    belongs_to :user

    has_many :stripe_charges

    validates_presence_of :user
    validates_presence_of :stripe_customer_id

  end
end