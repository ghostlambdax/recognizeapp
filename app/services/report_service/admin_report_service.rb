# TODO: add setting(s) for admin report interval
# QUESTION: how to handle if multiple intervals are selected
#           Say company selects all intervals: daily, week, month, quarter, and year
#           Should the report thats sent on the start of the year send 5 emails, or just the yearly?
#           You might think just send the yearly, but what if company has a process around the weekly
#           and still wants the weekly in addition to the higher order summary? Well, then company
#           can just deselect the higher order report i guess. 
module ReportService
  class AdminReportService < Base
    def recipients
      company.company_admins
    end

    def recipient_email_setting_filter
      { allow_admin_report_mailer: true }
    end

    def email_for_recipient(admin)
      EngagementReportMailer.admin_report(admin, report)
    end

    # note: the emails are sent even if all managers are disabled
    # as the parent method doesn't check manager status
    def self.should_run_for_company?(company)
      super && company.eligible_for_engagement_report_mailer?(:admin)
    end

    private

    # report is the same for all admins, so fetch it once and memoize
    def report
      opts = {time: reference_time, **custom_run_opts}
      @report ||= Report::Engagement::UsersReport.of_managers(company, report_interval, opts)
    end
  end
end
