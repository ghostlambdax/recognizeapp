class UserCompanyRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :user_company_roles do |t|
      t.integer :user_id, null: false
      t.integer :company_id, null: false
      t.timestamps null: false
    end
  end
end
