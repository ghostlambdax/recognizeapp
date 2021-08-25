class AddDeniedByColumnsToRedemptions < ActiveRecord::Migration[4.2]
  def change
    add_column :redemptions, :denier_id, :integer
    add_column :redemptions, :denied_at, :datetime
  end
end
