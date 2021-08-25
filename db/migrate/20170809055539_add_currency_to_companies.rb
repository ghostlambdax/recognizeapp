class AddCurrencyToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :currency, :string, default: "USD"
  end
end
