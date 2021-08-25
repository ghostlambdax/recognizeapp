#
# This is a new class created in 2020, unrelated to the old one with the same name
# it contains manually extracted mailer code from EmailBlast relevant to DailyEmailService
#
class IntervalNotifier < ApplicationMailer
  include MailHelper

  helper :mail

  # adapted from EmailBlast#daily_blast
  def daily_email(user, company_report)
    @user = user
    @interval = company_report.interval
    @user_report = Report::User.new(@user, company_report.from, company_report.to)
    @recognitions = company_report.top_public_recognitions
    @mail_styler = company_styler(user.company)
    subject = I18n.t("notifier.company_daily_recognitions", company: @user.company.name.humanize, count: @recognitions.count)

    I18n.with_locale(user.locale) do
      mail(to: @user.email, subject: subject, track_opens: true)
    end
  end
end
