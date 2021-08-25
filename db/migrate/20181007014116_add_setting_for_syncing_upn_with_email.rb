class AddSettingForSyncingUpnWithEmail < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :sync_email_with_upn, :boolean, default: false
  end
end
