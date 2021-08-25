class AddRedeemableFlagToPointActivity < ActiveRecord::Migration[4.2]
  def change
    add_column :point_activities, :is_redeemable, :boolean
  end
end
