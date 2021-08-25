class AddQuantityToRewards < ActiveRecord::Migration[4.2]
  def change
    add_column :rewards, :quantity, :integer, default: nil
    add_column :rewards, :quantity_interval_id, :integer
  end
end
