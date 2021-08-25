class AddTimestampsToWebhookEvents < ActiveRecord::Migration[6.0]
  def change
    add_timestamps :webhook_events
  end
end
