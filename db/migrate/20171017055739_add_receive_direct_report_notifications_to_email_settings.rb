class AddReceiveDirectReportNotificationsToEmailSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :email_settings, :receive_direct_report_notifications, :boolean, default: true
  end
end
