class AddMicrosoftTeamsIdToCompanies < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :microsoft_team_id, :string
  end
end
