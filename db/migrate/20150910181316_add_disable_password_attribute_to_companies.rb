class AddDisablePasswordAttributeToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :disable_passwords, :boolean, default: false
  end
end
