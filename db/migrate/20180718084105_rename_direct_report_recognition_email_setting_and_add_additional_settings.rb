class RenameDirectReportRecognitionEmailSettingAndAddAdditionalSettings < ActiveRecord::Migration[5.0]
  def change
    rename_column :email_settings, :receive_direct_report_notifications, :receive_direct_report_peer_recognition_notifications
    change_column_default :email_settings, :receive_direct_report_peer_recognition_notifications, nil

    add_column :email_settings, :receive_direct_report_anniversary_notifications, :boolean
    add_column :email_settings, :receive_direct_report_birthday_notifications, :boolean
  end
end
