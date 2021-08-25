class AddDeletedAtToTeamsAndUserTeams < ActiveRecord::Migration[4.2]
  def change
    add_column :teams, :deleted_at, :datetime
    add_column :user_teams, :deleted_at, :datetime
  end
end
