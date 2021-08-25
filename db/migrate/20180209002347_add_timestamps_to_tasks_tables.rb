class AddTimestampsToTasksTables < ActiveRecord::Migration[4.2]
  def change
    [:tasks, :completed_tasks, :task_submissions, :categories].each do |table|
      add_column table, :created_at, :datetime, null: false
      add_column table, :updated_at, :datetime, null: false
    end
  end
end
