class EnableNullForDirectReportNotificationFromEmailSettings < ActiveRecord::Migration[5.0]
  def up
    change_column_null :email_settings, :receive_direct_report_notifications, true
  end

  def down
    change_column_null :email_settings, :receive_direct_report_notifications, false
  end
end
