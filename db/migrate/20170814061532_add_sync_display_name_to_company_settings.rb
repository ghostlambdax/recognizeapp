class AddSyncDisplayNameToCompanySettings < ActiveRecord::Migration[4.2]
  def change
    add_column :company_settings, :sync_display_name, :boolean, default: true
  end
end
