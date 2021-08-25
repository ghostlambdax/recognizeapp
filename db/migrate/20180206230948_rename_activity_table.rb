class RenameActivityTable < ActiveRecord::Migration[4.2]
  def change
    rename_table :activities, :task_submissions
  end
end
