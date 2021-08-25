class EngagementReportMailer < ApplicationMailer
  include MailHelper
  include IntervalHelper

  default from: "Recognize Team <team@recognizeapp.com>"
  helper :mail, :interval

  # for faster processing in loop, get report once outside loop
  # and pass in for each user
  def admin_report(admin, report)
    @company = admin.company
    @report = report
    subject = I18n.t('engagement_report.admin.email_subject', count: @report.sent_recognition_count, interval: reset_interval_noun(@report.interval)).capitalize

    @mail_styler = company_styler(admin.company)

    @top_sending_managers = report.top_recognition_senders
    @bottom_sending_managers = report.bottom_recognition_senders
    @user = admin

    I18n.with_locale(@user.locale) do
      mail(to: @user.email, subject: subject, track_opens: true)
    end
  end

  # for faster processing in loop, get report once outside loop
  # and pass in for each user
  def manager_report(manager, report)
    subject = I18n.t('engagement_report.manager.email_subject', manager_count: report.sent_recognitions_count, interval: reset_interval_noun(report.interval), direct_sent: report.direct_report_sent_count, count: report.sent_recognitions_count).capitalize
    @company = manager.company
    @user = manager
    @report = report
    @mail_styler = company_styler(@user.company)

    @top_receiving_reports = @report.top_user_reports
    @bottom_receiving_reports = @report.bottom_user_reports

    I18n.with_locale(@user.locale) do
      mail(to: @user.email, subject: subject, track_opens: true)
    end
  end

end




