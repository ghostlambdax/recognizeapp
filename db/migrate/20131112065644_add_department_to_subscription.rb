class AddDepartmentToSubscription < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :department, :text
  end
end
