class CreateMsTeamsConfigs < ActiveRecord::Migration[5.0]
  def change
    create_table :ms_teams_configs do |t|
      t.integer :company_id, index: true
      t.string :entity_id
      t.text :settings, limit: 4294967295
      t.timestamps
    end
  end
end
