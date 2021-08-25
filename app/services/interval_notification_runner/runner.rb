module IntervalNotificationRunner
  class Runner
    attr_reader :run_report

    def initialize(report_class, company_ids, dry_run, reference_time,
                   hour_to_run: , custom_run_condition: nil, **custom_run_opts)
      @report_class = report_class
      @company_ids = company_ids
      @dry_run = dry_run
      @reference_time = reference_time
      @hour_to_run = hour_to_run
      @custom_run_condition = custom_run_condition
      @run_report = Reports::RunReport.new
      @custom_run_opts = custom_run_opts
    end

    # Timezone note: Apart from returning relevant company_ids according to their timezones,
    #                TimezoneEnforcer also changes the current timezone within the block to the relevant value
    #                which makes the report intervals honor the company timezone
    def invoke
      company_scope = Company.program_enabled
      company_scope = company_scope.where(id: company_ids) if company_ids
      TimezoneEnforcer.run(hour_to_run: hour_to_run, reference_time: reference_time,
                           company_scope: company_scope) do |company_ids_in_tz, time_in_zone|
        company_ids_in_tz.each do |cid|
          company = Company.find(cid)
          @reference_time = time_in_zone
          next unless company_filters_matched?(company)

          result = trigger_run(cid, dry_run)
          run_report.push(company, result) if result
        end
      end
      run_report
    end

    def trigger_run(cid, dry_run)
      report_class.new(cid, reference_time: reference_time, dry_run: dry_run, **custom_run_opts).run
    rescue => e
      custom_message = 'Error when instantiating report_class or invoking run'
      handle_exception(cid, e, custom_message)
      error_report(e, custom_message)
    end

    private

    def company_filters_matched?(company)
      should_run_for_company?(company) && custom_run_condition_matched?(company, reference_time)
    rescue => e
      custom_message = 'Error when checking company filters'
      handle_exception(company.id, e, custom_message)
      run_report.push(company, error_report(e, custom_message))
      false
    end

    attr_reader :report_class, :company_ids, :dry_run, :reference_time,
                :hour_to_run, :custom_run_condition,
                :custom_run_opts
    alias_method :dry_run?, :dry_run
    delegate :should_run_for_company?, to: :report_class

    def custom_run_condition_matched?(company, ref_time)
      return true if custom_run_condition.nil?

      !!custom_run_condition.call(ref_time)
    end

    def handle_exception(cid, e, warn_message)
      unless dry_run?
        Rails.env.production? ? notify_exception(cid, e, warn_message) : raise(e)
      end
    end

    def notify_exception(cid, e, warn_message)
      Rails.logger.warn("#{report_class}: #{warn_message}: #{e.inspect}")
      ExceptionNotifier.notify_exception(e, data: {report_class: report_class.to_s, company_id: cid})
    end

    def error_report(exception, custom_message)
      emails = []
      error_str = "#{custom_message}: #{exception.inspect}"
      # no recipients here, because this error is happening on the level of company / report-class
      errors = {error_str => []}
      IntervalNotificationRunner::DeliveryHandler::DeliveryReport.new(emails, errors)
    end
  end
end