class AddSettingForWebhooksToCompanySettings < ActiveRecord::Migration[6.0]
  def change
    add_column :company_settings, :allow_webhooks, :boolean, default: false
  end
end
