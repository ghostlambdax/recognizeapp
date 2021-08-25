class AddIntervalToSubscription < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :charge_interval, :string
  end
end
