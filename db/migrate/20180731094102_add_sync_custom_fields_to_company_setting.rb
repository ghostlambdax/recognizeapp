class AddSyncCustomFieldsToCompanySetting < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :sync_custom_fields, :boolean, default: false
  end
end
