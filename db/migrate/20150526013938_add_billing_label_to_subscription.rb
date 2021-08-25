class AddBillingLabelToSubscription < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :billing_label, :string
  end
end
