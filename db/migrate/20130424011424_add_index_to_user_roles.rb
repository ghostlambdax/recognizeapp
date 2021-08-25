class AddIndexToUserRoles < ActiveRecord::Migration[4.2]
  def change
    add_index :user_roles, :user_id
    add_index :user_roles, :role_id
    add_index :user_roles, [:user_id, :role_id]
  end
end
