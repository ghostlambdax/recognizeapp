class AddSyncDepartmentToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :sync_department, :boolean, default: true
    add_column :company_settings, :sync_country, :boolean, default: true
  end
end
