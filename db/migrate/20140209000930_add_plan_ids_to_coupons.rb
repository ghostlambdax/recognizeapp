class AddPlanIdsToCoupons < ActiveRecord::Migration[4.2]
  def change
    add_column :coupons, :plan_ids, :text
  end
end
