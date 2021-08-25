class AddIndexToDelayedJobs < ActiveRecord::Migration[5.0]
  def change
    add_index :delayed_jobs, [:queue], :name => 'delayed_jobs_queue'
  end
end
