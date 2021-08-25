class CreateCompanyRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :company_roles do |t|
      t.integer :company_id, null: false
      t.string :name, null: false
      t.timestamps null: false
    end
  end
end
