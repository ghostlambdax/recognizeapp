class AddAdditionalEmailSettingsToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column(:company_settings, :default_receive_direct_report_peer_recognition_notifications, :boolean, default: false)
    add_column(:company_settings, :default_receive_direct_report_anniversary_notifications, :boolean, default: false)
    add_column(:company_settings, :default_receive_direct_report_birthday_notifications, :boolean, default: false)
  end
end
