class ChangeDefaultOfWebhookActiveField < ActiveRecord::Migration[6.0]
  def change
    change_column_default :webhook_endpoints, :is_active, false
  end
end
