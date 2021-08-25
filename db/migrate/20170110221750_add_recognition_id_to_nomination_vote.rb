class AddRecognitionIdToNominationVote < ActiveRecord::Migration[4.2]
  def change
    add_column :nomination_votes, :recognition_id, :integer
  end
end
