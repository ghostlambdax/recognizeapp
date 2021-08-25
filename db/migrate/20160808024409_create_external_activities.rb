class CreateExternalActivities < ActiveRecord::Migration[4.2]
  def change
    create_table :external_activities do |t|
      t.string(:name, null: false)
      t.integer(:actor_id, null: false)
      t.string(:receiver_id)
      t.string(:target_id)
      t.string(:target_name)
      t.string(:group_id)
      t.integer(:company_id, null: false)
      t.string(:source, null: false)
      t.string(:source_id, null: false)
      t.text(:source_metadata)
      t.timestamp(:created_at, null: false)
      t.timestamp(:synced_at)
    end
  end
end
