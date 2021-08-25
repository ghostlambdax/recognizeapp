class RemoveTaskSubmissionsRequireTasksFromCompanySettings < ActiveRecord::Migration[4.2]
  def change
    remove_column :company_settings, :task_submissions_require_tasks, :boolean, default: false
  end
end
