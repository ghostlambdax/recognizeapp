class ChangeSyncAttributesDefaultValues < ActiveRecord::Migration[4.2]
  def change
    change_column :company_settings, :sync_phone_data, :boolean, :default => true
    change_column :company_settings, :sync_service_anniversary_data, :boolean, :default => true
    change_column :company_settings, :sync_managers, :boolean, :default => true

    # Update Null values to true
    sql = "UPDATE company_settings SET company_settings.sync_phone_data = true WHERE company_settings.sync_phone_data IS NULL"
    ActiveRecord::Base.connection.execute(sql)

    sql = "UPDATE company_settings SET company_settings.sync_service_anniversary_data = true WHERE company_settings.sync_service_anniversary_data IS NULL"
    ActiveRecord::Base.connection.execute(sql)

    sql = "UPDATE company_settings SET company_settings.sync_managers = true WHERE company_settings.sync_managers IS NULL"
    ActiveRecord::Base.connection.execute(sql)
  end
end
