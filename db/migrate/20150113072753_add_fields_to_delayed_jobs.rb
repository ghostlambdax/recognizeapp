class AddFieldsToDelayedJobs < ActiveRecord::Migration[4.2]
  def change
    add_column :delayed_jobs, :signature, :string
    add_column :delayed_jobs, :args, :text, limit: 4294967295
  end
end
