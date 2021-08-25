class RemoveServiceAnniversarySettingFromCompanies < ActiveRecord::Migration[4.2]
  def up
    remove_column :companies, :is_service_anniversary_enabled
  end

  def down
    add_column :companies, :is_service_anniversary_enabled, :boolean, default: false
  end

end
