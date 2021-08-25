class AddDeletedAtToRewardsAndRedemptions < ActiveRecord::Migration[4.2]
  def change
    add_column :rewards, :deleted_at, :datetime
    add_column :redemptions, :deleted_at, :datetime

  end
end
