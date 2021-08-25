class AddFieldsToRedemptions < ActiveRecord::Migration[4.2]
  def change
    add_column :redemptions, :points_at_redemption_time, :integer
    add_column :rewards, :enabled, :boolean, default: true
  end
end
