class AddHidePointsToSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :hide_points, :boolean, default: false
  end
end
