module IntervalNotificationRunner
  class DeliveryHandler
    attr_reader :delivery_report
    DeliveryReport = Struct.new(:emails, :errors)

    def initialize(report_instance, recipients, dry_run, email_setting_filter)
      @report_instance = report_instance
      @recipients = recipients
      @dry_run = dry_run
      @email_setting_filter = email_setting_filter
      @delivery_result = {}
      @failure_report = FailureReport.new
      @captured_emails = []
    end

    def invoke
      send_emails
      handle_failures
      @delivery_report = DeliveryReport.new(delivery_result[:emails], delivery_result[:errors])
    end

    private

    attr_reader :recipients, :dry_run, :report_instance, :delivery_result, :failure_report, :captured_emails, :email_setting_filter
    alias_method :dry_run?, :dry_run
    delegate :email_for_recipient, :company, to: :report_instance

    # Filters by global setting as well as (optionally) specific setting
    # also excludes users without email
    #
    # Note: this approach of filtering directly as a query imposes a limitation on recipients() that it must be a query too (and not array)
    #       if that limitation becomes problematic later, this filtering can instead be done inside the recipient loop in send_emails()
    def recipients_filtered_by_email_setting
      recipients
        .where.not(email: nil)
        .includes(:email_setting)
        .where(email_settings: email_setting_filter.merge(global_unsubscribe: false))
    end

    def send_emails
      recipients_filtered_by_email_setting.each do |user|
        fetch_and_handle_email_for(user) if user_eligible_for_email?(user)
      end

      delivery_result[:emails] = captured_emails
    end

    # this is only an additional safeguard before sending
    # that checks some generic attributes
    # the authoritative filtering for these conditions happen elsewhere
    #
    # Marking these as exceptions because they are unexpected cases
    # (unless the report is manually instantiated & run for invalid companies)
    def user_eligible_for_email?(user)
      eligible = true

      # filtered in Runner#invoke when filtering company
      unless user.company.program_enabled?
        message = "DeliveryHandler (double-check): program not enabled for company, skipping"
        failure_report.push(message, user)
        eligible = false
      end

      # specified by the end report class as a class method
      # filtered in Runner#invoke when filtering company
      unless report_instance.class.should_run_for_company?(user.company)
        message = "DeliveryHandler (double-check): company run condition specified in the singleton report class does not match, skipping"
        failure_report.push(message, user)
        eligible = false
      end

      # filtered in this same class in #recipients_filtered_by_email_setting
      if user.email_setting.global_unsubscribe?
        message = "DeliveryHandler (double-check): global_unsubscribe is true for user, skipping"
        failure_report.push(message, user)
        eligible = false
      end

      eligible
    end

    def fetch_and_handle_email_for(user)
      if (email = email_for_recipient(user))
        email.deliver unless dry_run?
        captured_emails << email
      end
    rescue => e
      failure_report.push("Error when fetching email_for_recipient: #{e.inspect}", user)
      # Raise error only if:
      #  - NOT dry run (as dry run errors are aggregated into the result email) AND
      #  - NOT production env: ExceptionNotifier is used for prod
      raise e unless Rails.env.production? || dry_run?
    end

    def handle_failures
      error_hash = failure_report.report_hash
      delivery_result[:errors] = error_hash
      return if error_hash.empty?

      notify_exceptions(error_hash) unless dry_run?
    end

    def notify_exceptions(error_hash)
      error_hash.each do |exception, recipient_emails|
        exception_data = {
          company_id: company.id,
          report_class: report_instance.class.to_s,
          recipients: recipient_emails
        }
        begin
          ExceptionNotifier.notify_exception(exception, exception_data)
        rescue TypeError
          # As of v4.4.3 of Exception notifier, we can't send a string to it.
          ExceptionNotifier.notify_exception(nil, exception_data)
        end
      end
    end

    class FailureReport
      # format: { <exception>: [<recipient_email>] }
      attr_reader :report_hash

      def initialize
        @report_hash = {}
      end

      # exception maybe an Exception or a String
      def push(exception, user)
        # converts to "#<class: message>" format
        exception = exception.inspect if exception.is_a? Exception
        (report_hash[exception] ||= []) << user.email
      end
    end
  end
end
