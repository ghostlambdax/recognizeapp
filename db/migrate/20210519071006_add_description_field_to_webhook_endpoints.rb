class AddDescriptionFieldToWebhookEndpoints < ActiveRecord::Migration[6.0]
  def change
    add_column :webhook_endpoints, :description, :string
  end
end
