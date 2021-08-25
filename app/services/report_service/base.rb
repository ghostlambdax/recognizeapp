module ReportService
  class Base
    include IntervalNotificationRunner
    run_at_hour 10, if: ->(ref_time) { first_monday_of_the_month?(ref_time) }

    # extended by sub classes
    def self.should_run_for_company?(company)
      company.managers.present?
    end

    def self.allowed_custom_run_opts
      [:interval, :shift]
    end

    def self.first_monday_of_the_month?(reference_time)
      start = reference_time.beginning_of_month.to_date
      first_monday = start.upto(start + 1.week).find(&:monday?)
      first_monday == reference_time.to_date
    end
    private_class_method :first_monday_of_the_month?

    private

    # used by sub classes
    # the default value is used for the class-level run() and thus in cron
    # the custom interval is for manual runs only; to be specified in the initializer
    def report_interval
      custom_run_opts[:interval] || Interval.monthly
    end
  end
end
