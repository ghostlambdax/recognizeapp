#
# I. SETUP
#   1. Include module
#   2. Setup time to run
#     - run_at <hour> [, if: -> { |ref_time| ... }]
#   3. Define Required Methods in the including class
#     i. Instance methods:
#       - recipients() # `company` is available implicitly as attr
#       - email_for_recipient(recipient)
#       - [optional] recipient_email_setting_filter()
#     ii. Class methods:
#       - should_run_for_company?(company)
#       - [optional] allowed_custom_run_opts()
#
# II. USAGE
#   invoke any one of the RunMethods (run, dry_run, forecast) directly on the including class
#   see RunMethods module for the accepted options for each method
#   you may need to pass a matching :reference_time argument, depending upon the report's run_at() config
#
#   Examples:
#     # Run at appropriate time for a company / report (following ex. is for engagement reports)
#     # Note: the time_ago_in_words shown in email is different in the 2 approaches below (:reference_time arg vs Timecop)
#     => test_company = Company.find_by_domain('planet.io')
#     => first_monday_this_month = (Date.current.beginning_of_month..Date.current + 1.week).detect(&:monday?)
#     => monday_ten_thirty_for_test_company = monday.to_time.change(hour: 10, min: 30).asctime.in_time_zone(test_company.settings.timezone)
#     => EngagementReports.run(reference_time: monday_ten_thirty_for_test_company)
#        OR
#        Timecop.freeze(monday_ten_thirty_for_test_company) { EngagementReports.run }
#
#     # Show the results of invoking run() at the current time, report emailed to site admins
#     # can be wrapped into suitable time, similar as above ex.
#     => ReportService::AdminReportService.dry_run
#
#     # forecast next 24 hours of runs. Checked hourly, report emailed to site admins
#     => DailyEmailService.forecast
#
#     # forecast next 1 month of runs
#     => ReportService::ManagerReportService.forecast(for: 1.month)
#
module IntervalNotificationRunner
  extend ActiveSupport::Concern

  include CoreModule::InstanceMethods
  class_methods do
    include CoreModule::RunMethods
    include CoreModule::ConfigMethods
  end

  included do
    # set in InstanceMethods#initialize
    attr_reader :company, :reference_time, :dry_run, :custom_run_opts
    alias_method :dry_run?, :dry_run

    # set in ConfigMethods#run_at_hour
    class_attribute :hour_to_run, :custom_run_condition, instance_accessor: false, instance_predicate: false
  end
end
