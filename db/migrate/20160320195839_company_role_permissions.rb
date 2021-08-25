class CompanyRolePermissions < ActiveRecord::Migration[4.2]
  def change
    create_table :company_role_permissions do |t|
      t.integer :company_role_id, null: false
      t.integer :permission_id, null: false
      t.timestamps null: false
    end
  end
end
