class AddCurrencyColumnsToFundsTables < ActiveRecord::Migration[5.0]
  def change
    add_column :funds_txns, :catalog_id, :integer
    add_column :funds_txns, :amount_currency_code, :string
    add_column :funds_accounts, :currency_code, :string
  end
end
