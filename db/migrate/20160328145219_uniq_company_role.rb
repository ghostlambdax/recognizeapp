class UniqCompanyRole < ActiveRecord::Migration[4.2]
  def change
    add_index :company_roles, [:name, :company_id], unique: true
  end
end
