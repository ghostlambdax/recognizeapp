class AddConditionsTemplateToWebhookEndpoints < ActiveRecord::Migration[6.0]
  def change
    add_column :webhook_endpoints, :conditions_template, :text
  end
end
