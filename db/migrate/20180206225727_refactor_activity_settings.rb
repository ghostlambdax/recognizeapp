class RefactorActivitySettings < ActiveRecord::Migration[4.2]
  def change
    rename_column :company_settings, :activities_enabled, :tasks_enabled
    rename_column :company_settings, :activities_require_tasks, :task_submissions_require_tasks

  end
end
