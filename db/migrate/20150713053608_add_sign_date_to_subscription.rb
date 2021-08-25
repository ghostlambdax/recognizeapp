class AddSignDateToSubscription < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :sign_date, :date
  end
end
