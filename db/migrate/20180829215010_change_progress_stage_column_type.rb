class ChangeProgressStageColumnType < ActiveRecord::Migration[5.0]
  def change
    change_column :delayed_jobs, :progress_stage, :text
  end
end
