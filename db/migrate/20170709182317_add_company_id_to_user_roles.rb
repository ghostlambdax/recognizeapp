class AddCompanyIdToUserRoles < ActiveRecord::Migration[4.2]
  def change
    add_column :user_roles, :company_id, :integer
    add_index :user_roles, :company_id
    add_index :user_roles, [:company_id, :role_id]
  end
end
