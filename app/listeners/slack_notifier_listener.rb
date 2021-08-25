class SlackNotifierListener
  SYSTEM_ADMIN_SLACK_HANDLES = '<!subteam^SQECBCGAW>'

  def on_company_created(company)
    return unless company.company_admin.present?

    Rails.logger.info "SlackNotifierListener#on_company_created: #{company.domain}|#{company.id}"
    url = "https://recognizeapp.com/admin?network=#{company.domain}"
    attachments = [{
      color: "good",
      fields: [
        {title: "Company", value: company.domain, short: true},
        {title: "Platform", value: platform(company), short: true},
        {title: "Invited", value: invited_status(company), short: true},
        {title: "Contact", value: "#{company.company_admin.full_name} - #{company.company_admin.email}", short: true},
        {title: "Contact Job Title", value: company.company_admin.job_title, short: true}
      ]
    }]
    send_async_slack_notification(text: "New signup: #{company.domain} - #{url}", attachments: attachments, channel: "#opportunities")
  end

  def on_redemption_pending(redemption)
    if redemption.reward.provider_reward?
      send_async_slack_notification(text: "[#{redemption.company.domain}] New gift card redemption: #{redemption.reward.title} $#{redemption.amount}", channel: "#system-notifications")
    else
      send_async_slack_notification(text: "[#{redemption.company.domain}] New company fulfilled redemption: #{redemption.reward.title} $#{redemption.amount}", channel: "#system-notifications")
    end
    notify_manager_disabled(redemption) if redemption.reward.manager&.disabled?
  end

  def on_redemption_approved(redemption)
    if redemption.reward.provider_reward?
      recognize_balance = ::TangoCard::Client.recognize_balance
      company_balance = redemption.company.primary_funding_account.balance.to_f
      send_async_slack_notification(text: "[#{redemption.company.domain}] New gift card approval: #{redemption.reward.title} $#{redemption.amount} | company balance: #{company_balance} | recognize balance: #{recognize_balance}", channel: "#system-notifications")

      if recognize_balance.to_f < 500
        send_async_slack_notification(text: "#{SYSTEM_ADMIN_SLACK_HANDLES} Recognize rewards balance is low. Time to top up!: #{recognize_balance}", channel: "#support-alerts")
      end

    else
      send_async_slack_notification(text: "[#{redemption.company.domain}] New company fulfilled redemption approval: #{redemption.reward.title} $#{redemption.amount}", channel: "#system-notifications")
    end
  end

  def on_redemption_denied(redemption)
    if redemption.reward.provider_reward?
      send_async_slack_notification(text: "[#{redemption.company.domain}] Gift card denied: #{redemption.reward.title} $#{redemption.amount}", channel: "#system-notifications")
    else
      send_async_slack_notification(text: "[#{redemption.company.domain}] Company fulfilled redemption denial: #{redemption.reward.title} $#{redemption.amount}", channel: "#system-notifications")
    end
  end

  def platform(company)
    auth = company.company_admin.try(:authentications).try(:first)
    platform = if auth.present?
      auth.provider.humanize
    else
      "Standalone"
    end
  end

  def invited_status(company)
    status = company.company_admin.try(:status)
    if status.present? && status.match(/^invited/)
      return status.humanize
    else
      "n/a"
    end
  end

  private

  def host
    domain = Recognize::Application.config.host.split('.')
    case domain.length
    when 2 then domain
    when 3 then domain.first
    end
  end

  def notify_manager_disabled(redemption)
    text = "[#{host}] User #{redemption.user.email} in #{redemption.company.domain} " +
        "requested redemption for reward but the manager is disabled - #{SYSTEM_ADMIN_SLACK_HANDLES}"
    send_async_slack_notification(text: text, channel: "#support-alerts")
  end

  def send_async_slack_notification(opts, queue = :priority)
    SlackNotifierJob.set(queue: queue).perform_later(opts)
  end
end
