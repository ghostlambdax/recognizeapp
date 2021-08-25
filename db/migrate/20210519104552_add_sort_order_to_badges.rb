class AddSortOrderToBadges < ActiveRecord::Migration[6.0]
  def change
    add_column :badges, :sort_order, :integer, default: 1
  end
end
