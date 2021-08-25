class AddRedeemedPointsColumnToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :redeemed_points, :integer, default: 0
  end
end
