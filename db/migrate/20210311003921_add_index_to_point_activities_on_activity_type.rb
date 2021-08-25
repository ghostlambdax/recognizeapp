class AddIndexToPointActivitiesOnActivityType < ActiveRecord::Migration[5.0]
  def change
    add_index :point_activities, [:company_id, :activity_type, :created_at], name: "pa_c_at_ts_index"
    add_index :point_activities, [:company_id, :activity_type, :badge_id, :team_id, :created_at], name: "pa_c_at_b_t_ts_index"
  end
end
