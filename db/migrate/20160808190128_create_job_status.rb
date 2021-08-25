class CreateJobStatus < ActiveRecord::Migration[4.2]
  def change
    create_table :job_status do |t|
      t.string :name, null: false
      t.integer :company_id, null: false
      t.integer :initiator_id
      t.integer :request_count, null: false, default: 0
      t.timestamp :started_at
      t.timestamp :stopped_at
    end
  end
end
