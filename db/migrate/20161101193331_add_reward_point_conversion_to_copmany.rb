class AddRewardPointConversionToCopmany < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :points_to_dollar_ratio, :decimal, precision: 10, scale: 2, default: 1
  end
end
