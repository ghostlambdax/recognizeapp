class AddSyncSettingsToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :sync_service_anniversary_data, :boolean, default: false
    add_column :companies, :sync_managers, :boolean, default: true
  end
end
