# frozen_string_literal: true

# this is just a thin wrapper now for triggering the report methods together on all the relevant report classes.
class EngagementReports
  REPORT_CLASSES = [ReportService::AdminReportService, ReportService::ManagerReportService].freeze

  class << self
    def run(opts = {})
      REPORT_CLASSES.map { |klass| klass.run(**opts) }
    end

    def dry_run(opts = {})
      REPORT_CLASSES.map { |klass| klass.dry_run(**opts) }
    end

    def forecast(opts = {})
      REPORT_CLASSES.map { |klass| klass.forecast(**opts) }
    end
  end
end
