class RemovePointsToCurrencyRatioFromCompanies < ActiveRecord::Migration[5.0]
  def change
    remove_column :companies,  :points_to_currency_ratio, :decimal, precision: 10, scale: 2, default: 1
  end
end
