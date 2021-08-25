class WebhookNotifier < ApplicationMailer
  include MailHelper
  helper :mail

  def notify_endpoint_disabled(endpoint)
    @endpoint = endpoint
    @last_response_code = endpoint.events.last&.response_status_code
    company_admins = endpoint.company.company_admins

    mail(to: company_admins.map(&:email), subject: _('[Action Required] Recognize webhook has been disabled due to repeated failed deliveries'))
  end
end
