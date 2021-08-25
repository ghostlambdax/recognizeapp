class ChangePointsTableToPlusones < ActiveRecord::Migration[4.2]
  def up
    rename_table :points, :plus_ones
  end

  def down
    rename_table :plus_ones, :points
  end
end
