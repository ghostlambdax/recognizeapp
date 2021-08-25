class DailyEmailService
  include IntervalNotificationRunner

  run_at_hour 6

  def recipients
    company.users.includes(:email_setting).

      # only send to active, verified users
      active.
      where.not(verified_at: nil).

      # non personal account users
      where.not(network: "users")
  end

  def recipient_email_setting_filter
    # and they accept this particular notification
    { daily_updates: true }
  end

  # Note: this could be checked at the company-level for better efficiency, but leaving it here
  #       so that the service is instantiated for all eligible companies and so they all show up in the dry run report
  def email_for_recipient(user)
    IntervalNotifier.daily_email(user, report) if report.top_public_recognitions.size > 0
  end

  def self.should_run_for_company?(company)
    company.allow_daily_emails?
  end

  # not allowing custom :interval as this is "Daily" email service
  def self.allowed_custom_run_opts
    [:shift]
  end

  private

  def report
    @report ||= begin
      interval = Interval.daily
      shift = custom_run_opts[:shift] || -1
      from = interval.start(shift: shift, time: reference_time)
      to = interval.end(shift: shift, time: reference_time)

      Report::Company.new(company, from, to, interval: interval)
    end
  end
end