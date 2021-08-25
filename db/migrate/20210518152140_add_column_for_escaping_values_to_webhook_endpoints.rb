class AddColumnForEscapingValuesToWebhookEndpoints < ActiveRecord::Migration[6.0]
  def change
    add_column :webhook_endpoints, :escape_all_values, :boolean, default: true
  end
end
