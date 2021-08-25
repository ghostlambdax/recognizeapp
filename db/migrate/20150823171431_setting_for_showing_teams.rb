class SettingForShowingTeams < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :allow_teams, :boolean, default: true
  end
end
