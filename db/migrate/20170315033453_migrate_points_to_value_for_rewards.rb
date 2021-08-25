class MigratePointsToValueForRewards < ActiveRecord::Migration[4.2]
  def up
    rename_column :rewards, :points, :deprecated_points
    add_column :rewards, :value, :float
    Reward.reset_column_information
    puts "Migrating Rewards points to value"
    Reward.all.each do |r|
      print "."
      val = Reward.convert_points_to_currency(r.deprecated_points, r.company)
      r.update_column(:value, val)
    end
    puts "Complete"
  end

  def down
    remove_column :value
    rename_column :deprecated_points, :points
  end
end
