class AddStatusToRedemptions < ActiveRecord::Migration[4.2]
  def change
    add_column :redemptions, :status, :string, default: 'pending'
  end
end
