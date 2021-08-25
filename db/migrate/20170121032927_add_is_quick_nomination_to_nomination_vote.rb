class AddIsQuickNominationToNominationVote < ActiveRecord::Migration[4.2]
  def change
    add_column :nomination_votes, :is_quick_nomination, :boolean, default: false
  end
end
