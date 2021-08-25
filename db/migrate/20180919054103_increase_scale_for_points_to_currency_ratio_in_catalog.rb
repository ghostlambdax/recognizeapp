class IncreaseScaleForPointsToCurrencyRatioInCatalog < ActiveRecord::Migration[5.0]
  def up
    change_column :catalogs, :points_to_currency_ratio, :decimal, precision: 10, scale: 5, default: 1
  end

  def down
    change_column :catalogs, :points_to_currency_ratio, :decimal, precision: 10, scale: 2, default: 1
  end
end
