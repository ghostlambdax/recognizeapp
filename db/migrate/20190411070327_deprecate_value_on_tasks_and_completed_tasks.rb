# Task values have been migrated to points
class DeprecateValueOnTasksAndCompletedTasks < ActiveRecord::Migration[5.0]
  def change
    rename_column :tasks, :value, :deprecated_value
    rename_column :completed_tasks, :value, :deprecated_value
  end
end
