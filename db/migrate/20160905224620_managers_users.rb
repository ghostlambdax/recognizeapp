class ManagersUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :manager_id, :integer
  end
end
