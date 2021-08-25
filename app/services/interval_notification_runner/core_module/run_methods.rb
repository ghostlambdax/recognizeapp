# frozen_string_literal: true

module IntervalNotificationRunner
  module CoreModule
    # class methods
    module RunMethods
      # master entry point for cron
      # Ex. ReportService::AdminReportService.run
      #
      # @param :reference_time [Time / TimeWithZone] the time with reference to which the run is invoked
      # @param :dry_run [Boolean] whether to trigger a simulated run with report sent to admins, or normal run with emails sent to actual recipients
      # @param :company_ids [Array, Integer, String] optional company filter
      # Note: additional params might be supported depending upon the client class, see if :allowed_custom_run_opts is defined
      #
      # @return [Reports::RunReport( results: Array<CompanyReport(:company, :emails, :errors)> )]
      #
      def run(reference_time: Time.current, dry_run: false, company_ids: nil, **custom_run_opts)
        validate_module_setup!
        validate_custom_params!(custom_run_opts)

        run_setup = { hour_to_run: self.hour_to_run, custom_run_condition: custom_run_condition }
        opts = {**run_setup, **custom_run_opts}
        # Note: using local variable over class variable (despite that approach being easier)
        # to prevent issues with multiple simultaneous runs, or even just consecutive runs
        runner = Runner.new(self, company_ids, dry_run, reference_time, opts)
        runner.invoke
      end

      # Dry run and email the result to admins
      # - accepts all the options allowed by run()
      # - additionally accepts :forecast mode option, used by the forecast() method
      #
      # @return [Mail::Message, Reports::RunReport] report if forecast mode, else dry run email
      #
      def dry_run(reference_time: Time.current, company_ids: nil, **opts)
        forecast_mode = opts.delete(:forecast)
        run_report = run(**opts, reference_time: reference_time, company_ids: company_ids, dry_run: true)

        if forecast_mode
          run_report
        else
          DryRunMailer.dry_run_email(run_report, self, reference_time, company_ids).deliver
        end
      end

      # Forecast future emails
      # And email the result to admins
      # The forecast runs for each hour between the target interval range
      #
      # Note: the loop runs over both start and end boundaries, so it will run n+1 times for n.hour duration
      #  for eg. runs 25 times by default - which is for 24.hour duration
      #
      # accepted options
      #   @param :for [ActiveSupport::Duration]
      #       duration to forecast starting with current time
      #       Defaults to next 24 hours
      #   @param :reference_time [Time / TimeWithZone]
      #       the start time for forecast
      #       can be used with :for option as an alternative format of specifying range
      #       Defaults to Time.current
      #   @param :time_range [Range of Time objects]
      #       The interval to forecast
      #       can be used instead of the :for arg to be more declarative
      #   @param :company_ids [Array]
      #       Filter for limiting the forecast to specific companies.
      #       Not active by default.
      #   * also accepts additional params allowed by run
      #
      # @return [Mail::Message] forecast email
      #
      # Usage Examples:
      #   # without any args
      #   # forecasts for 1 day starting from current time
      #   - DailyEmailService.forecast
      #
      #   # with explicit :time_range
      #   # "forecast" past week
      #   - DailyEmailService.forecast(time_range: Time.current-7.days..Time.current)
      #
      #   # with :for
      #   # forecast for one month starting with current time
      #   - AdminReportService.forecast(for: 1.month)
      #
      #   # with :reference_time and :for
      #   # forecasts for 12 hours starting with reference_time
      #   - ManagerReportService.forecast(reference_time: Time.zone.parse('2020-01-05'), for: 12.hours)
      #
      def forecast(time_range: nil, reference_time: nil, company_ids: nil, **opts)
        raise ArgumentError, 'you cannot specify both :time_range and :for' if time_range && opts[:for]
        raise ArgumentError, 'you cannot specify both :time_range and :reference_time' if time_range && reference_time

        if time_range.nil?
          reference_time ||= Time.current
          duration = opts.delete(:for) || 1.day
          time_range ||= reference_time..(reference_time + duration)
        end

        range_in_unix_timestamp = time_range.begin.to_i..time_range.end.to_i
        hours = range_in_unix_timestamp.step(1.hour)
        raise ArgumentError, 'start time must be earlier than end time (in hours)' if hours.count.zero?

        report = forecast_and_get_report(company_ids, hours, opts)
        DryRunMailer.forecast_email(report, self, time_range, company_ids, hours.count).deliver
      end

      # Methods to be defined by client classes: BEGIN #
      def should_run_for_company?(_company)
        raise AbstractMethodError, :should_run_for_company?
      end

      # optional: additional arguments allowed for run / dry_run
      # to be used by the service classes (usually for the report)
      # whitelisting this disallows arbitrary keys, preventing typos and unsupported arguments beforehand
      def allowed_custom_run_opts
        []
      end
      # Methods to be defined by client classes: END #

      # this is checked in class as well as instance level
      # keeping this public for the instance access
      def validate_custom_params!(params)
        return if params.blank?

        unknown_keys = params.keys - allowed_custom_run_opts
        raise ArgumentError, "unknown run parameter(s): #{unknown_keys}" if unknown_keys.present?
      end

      private

      def forecast_and_get_report(company_ids, hours, opts)
        Reports::ForecastReport.new.tap do |forecast_report|
          hours.each do |ref_timestamp|
            ref_time = Time.zone.at(ref_timestamp)
            run_report = dry_run(reference_time: ref_time, company_ids: company_ids, forecast: true, **opts)
            forecast_report.push(ref_time, run_report) if run_report.company_count.positive?
          end
        end
      end

      def validate_module_setup!
        raise 'IntervalNotificationRunner: missing run_at_hour() setup' if hour_to_run.nil?
      end
    end
  end
end