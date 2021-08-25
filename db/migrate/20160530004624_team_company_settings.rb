class TeamCompanySettings < ActiveRecord::Migration[4.2]
  def change
    add_column(:companies, :sync_teams, :boolean, default: false, nil: false)
    add_column(:teams, :synced_at, :timestamp)
    add_column(:teams, :yammer_id, :integer)
  end
end
