class RemoveNameFromSubscriptions < ActiveRecord::Migration[4.2]
  def up
    remove_column :subscriptions, :name
    remove_column :subscriptions, :price
    add_column :subscriptions, :unit_price, :decimal
  end

  def down
    add_column :subscriptions, :name, :string
    add_column :subscriptions, :price, :decimal
    remove_column :subscriptions, :unit_price
  end
end
