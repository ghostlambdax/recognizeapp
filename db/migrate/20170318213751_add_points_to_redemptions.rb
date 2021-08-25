class AddPointsToRedemptions < ActiveRecord::Migration[4.2]
  def change
    add_column :redemptions, :points_redeemed, :integer
    add_column :redemptions, :value_redeemed, :float
  end
end
