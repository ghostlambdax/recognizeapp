class AddSettingForAllowingSmsNotifications < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :allow_sms_notifications, :boolean, default: false
    add_column :email_settings, :allow_sms_notifications, :boolean, default: true
  end
end
