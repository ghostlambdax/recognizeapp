class AddSyncReportNotificationEmailsToCompanySetting < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :user_ids_to_notify_of_sync_report, :text
  end
end
