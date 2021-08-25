class AddRedeemablePointsToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :redeemable_points, :integer, default: 0, null: false
  end
end
