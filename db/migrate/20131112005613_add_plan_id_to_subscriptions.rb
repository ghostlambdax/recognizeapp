class AddPlanIdToSubscriptions < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :plan_id, :integer
  end
end
