class CreateStripeCharges < ActiveRecord::Migration[4.2]
  def change
    create_table :stripe_charges do |t|
      t.references :user_stripe_customer, index: true
      t.string :stripe_charge_id
      t.decimal :amount, precision: 10, scale: 2

      t.timestamps
    end
  end
end
