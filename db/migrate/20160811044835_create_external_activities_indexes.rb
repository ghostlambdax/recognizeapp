class CreateExternalActivitiesIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :external_activities, :actor_id
    add_index :external_activities, :receiver_id
    add_index :external_activities, :company_id
    add_index :external_activities, :group_id
    add_index :external_activities, :name
    add_index :external_activities, :source
    add_index :external_activities, [:name, :source_id, :source, :company_id, :actor_id, :receiver_id], name: "uniq_external_activity", unique: true
  end
end
