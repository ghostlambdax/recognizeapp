class MigrateDataForPointActivityTeamIndices < ActiveRecord::Migration[5.0]
  def up
    if PointActivityTeam.count > 0
      puts " ------------------- "
      puts "Hi there. We need to update your data to add company and recognition id to PointActivityTeams"
      puts "Depending on the size of your database this might take a few minutes."
      puts "Please standby... :) "    
        PointActivityTeam.joins(:point_activity).update_all(
          "point_activity_teams.company_id = point_activities.company_id, point_activity_teams.recognition_id = point_activities.recognition_id"
        )
    end
  end
end
