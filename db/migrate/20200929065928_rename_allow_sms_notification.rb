class RenameAllowSmsNotification < ActiveRecord::Migration[5.0]
  def change
    rename_column :companies, :allow_sms_notifications, :allow_recognition_sms_notifications
    rename_column :email_settings, :allow_sms_notifications, :allow_recognition_sms_notifications
  end
end
