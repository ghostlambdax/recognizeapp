class AddAmountToSubscriptions < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :amount, :decimal
  end
end
