class AddLastNominationAwardedAtOnTeams < ActiveRecord::Migration[4.2]
  def change
    add_column :teams, :last_nomination_awarded_at, :datetime
  end
end
