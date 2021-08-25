class RenameActivityIdColumns < ActiveRecord::Migration[4.2]
  def change
    rename_column :completed_tasks, :activity_id, :task_submission_id
  end
end
