class AddSettingForGoogleImport < ActiveRecord::Migration[4.2]
  def change
    rename_column :companies, :allow_google_sync, :allow_google_login
    add_column :companies, :allow_google_contact_import, :boolean, default: true
  end
end
