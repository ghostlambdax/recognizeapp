class AddQuantityToSubscriptions < ActiveRecord::Migration[4.2]
  def up
    add_column :subscriptions, :quantity, :integer
    Subscription.all.each do |subscription|
      subscription.quantity = Stripe::Customer.retrieve(subscription.stripe_customer_token).subscriptions.first.quantity rescue nil
      subscription.save
    end
  end

  def down
    remove_column :subscriptions, :quantity
  end
end
