class AddBadgeIdToPointActivity < ActiveRecord::Migration[4.2]
  def change
    add_column :point_activities, :badge_id, :integer
    add_index :point_activities, :badge_id
  end
end
