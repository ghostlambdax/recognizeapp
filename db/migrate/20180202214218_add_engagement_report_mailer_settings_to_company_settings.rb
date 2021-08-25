class AddEngagementReportMailerSettingsToCompanySettings < ActiveRecord::Migration[4.2]
  def change
    add_column(:companies, :allow_admin_report_mailer, :boolean, default: true)
    add_column(:companies, :allow_manager_report_mailer, :boolean, default: true)

    add_column(:email_settings, :allow_admin_report_mailer, :boolean, default: true)
    add_column(:email_settings, :allow_manager_report_mailer, :boolean, default: true)
  end
end
