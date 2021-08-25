class ChangeColumnTypeOfReceiverIdOnExternalActivities < ActiveRecord::Migration[4.2]
  def change
    change_column :external_activities, :receiver_id, :integer
  end
end
