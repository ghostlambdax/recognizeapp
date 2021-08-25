class AddResetColumnsToPointActivities < ActiveRecord::Migration[4.2]
  def change
    add_column :point_activities, :reset_at, :datetime
    add_column :point_activities, :reset_by_id, :integer
    add_index :point_activities, :is_redeemable
    add_index :point_activities, [:company_id, :is_redeemable]
  end
end
