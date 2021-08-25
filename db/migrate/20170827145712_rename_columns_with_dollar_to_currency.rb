class RenameColumnsWithDollarToCurrency < ActiveRecord::Migration[4.2]
  def change
    rename_column :companies, :points_to_dollar_ratio, :points_to_currency_ratio
    rename_column :companies, :has_set_points_to_dollar_ratio, :has_set_points_to_currency_ratio
  end
end
