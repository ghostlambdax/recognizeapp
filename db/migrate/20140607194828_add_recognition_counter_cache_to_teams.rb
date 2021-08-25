class AddRecognitionCounterCacheToTeams < ActiveRecord::Migration[4.2]
  def change
    add_column :teams, :received_recognitions_count, :integer
  end
end
