class RenamePlusOneToRecognitionApprovals < ActiveRecord::Migration[4.2]
  def up
    rename_table :plus_ones, :recognition_approvals
  end

  def down
    rename_table :recognition_approvals, :plus_ones
  end
end
