class AddSettingsForActivities < ActiveRecord::Migration[4.2]
  def change
    add_column :company_settings, :activities_enabled, :boolean, default: true
    add_column :company_settings, :activities_require_tasks, :boolean, default: false

    CompanySetting.reset_column_information
    CompanySetting.update_all(activities_enabled: false)
  end
end
