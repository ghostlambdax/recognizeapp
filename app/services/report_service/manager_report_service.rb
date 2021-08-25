module ReportService
  class ManagerReportService < Base
    def recipients
      company.managers(with_atleast_one_active_report: true).active
    end

    def recipient_email_setting_filter
      { allow_manager_report_mailer: true }
    end

    def email_for_recipient(manager)
      EngagementReportMailer.manager_report(manager, report_for(manager))
    end

    def self.should_run_for_company?(company)
      super && company.eligible_for_engagement_report_mailer?(:manager)
    end

    private

    def report_for(manager)
      opts = {time: reference_time, **custom_run_opts}
      Report::Engagement::ManagerReport.new(manager, report_interval, opts)
    end
  end
end
