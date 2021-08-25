class AddCounterToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :accounts_available, :integer, default: 1
  end
end
