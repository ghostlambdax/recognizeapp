class AddSyncSettingsColumnToCompanySettings < ActiveRecord::Migration[4.2]
  def change
    add_column(:company_settings, :sync_phone_data, :boolean)
    add_column(:company_settings, :sync_service_anniversary_data, :boolean)
    add_column(:company_settings, :sync_managers, :boolean)
  end
end
