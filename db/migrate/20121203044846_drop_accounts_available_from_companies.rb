class DropAccountsAvailableFromCompanies < ActiveRecord::Migration[4.2]
  def up
    remove_column :companies, :accounts_available
  end

  def down
    add_column :companies, :accounts_available, :integer
  end
end
