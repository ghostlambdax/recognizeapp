class StripeService

  #
  # Service method to create a stripe customer for a user
  #
  # The customer is created at Stripe and saved locally as a UserStripeCustomer
  #
  def self.create_stripe_customer(user, stripe_token)
    customer = Stripe::Customer.create(source: stripe_token)
    Rewards::UserStripeCustomer.create(user: user, stripe_customer_id: customer.id)
  end
  
  #
  # Service method to charge a user's stripe account
  #
  # Takes a UserStripeCustomer and an amount as inputs
  # The amount should be a decimal representation of the dollar 
  # amount (i.e., 100.00 for one hundred dollars).
  #
  # It then charges stripe and saves it as a StripeCharge entry
  # Exceptions are returned to the caller so they can be dealt with
  # at a higher level, since handling them from a controller would
  # be different than from a background job
  #
  def self.charge_by_stripe_customer(stripe_customer, amount)
    charge = Stripe::Charge.create(
      amount: Integer(amount * 100), 
      currency: "usd",
      customer: stripe_customer.stripe_customer_id,
      description: "Adding funds for Recognize rewards balance")

    # save our transaction if successful
    Rewards::StripeCharge.create(user_stripe_customer: stripe_customer, 
                        stripe_charge_id: charge.id, 
                        amount: amount)
  end
  
end