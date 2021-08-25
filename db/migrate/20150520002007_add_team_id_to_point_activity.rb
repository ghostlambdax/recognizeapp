class AddTeamIdToPointActivity < ActiveRecord::Migration[4.2]
  def change
    add_column :point_activities, :team_id, :integer
    add_index :point_activities, :team_id
  end
end
