class CreateUserStripeCustomers < ActiveRecord::Migration[4.2]
  def change
    create_table :user_stripe_customers do |t|
      t.references :user, index: true
      t.string :stripe_customer_id

      t.timestamps
    end
  end
end
