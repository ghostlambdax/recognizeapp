class AddCompanyIdAndRecognitionIdToPointActivityTeams < ActiveRecord::Migration[5.0]
  def change
    add_column :point_activity_teams, :company_id, :integer
    add_column :point_activity_teams, :recognition_id, :integer

    add_index :point_activity_teams, :company_id
    add_index :point_activity_teams, [:company_id, :team_id], name: "pat_company_team"
    add_index :point_activity_teams, [:company_id, :recognition_id], name: "pat_company_recognition"
    add_index :point_activity_teams, [:company_id, :team_id, :recognition_id], name: "pat_company_team_recognition"
  end
end
