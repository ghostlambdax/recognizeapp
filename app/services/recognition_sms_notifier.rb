class RecognitionSmsNotifier
  include Rails.application.routes.url_helpers

  def on_recognition_status_changed_to_approved(recognition)
    return unless recognition.approved?
    return unless recognition.authoritative_company.allow_recognition_sms_notifications?
    return if recognition.skip_notifications

    recipients = recognition.user_recipients
    recipients.each do |r|
      SmsNotifierJob.perform_later(r.id, content(recognition, r)) if r.accepts_email?(:allow_recognition_sms_notifications)
    end
    # ExceptionNotifier.notify_exception(e, {data: {recognition: recognition.slug}})
  end

  def sender(recognition)
    recognition.sender_name
  end

  def content(recognition, recipient)
    url_opts = {host: Recognize::Application.config.host}
    unless recipient.active?
      recipient.reset_perishable_token! if recipient.perishable_token.blank?
      url_opts[:invite] = recipient.perishable_token
    end

    locale = recipient.locale || 'en'

    content = I18n.with_locale(locale) do
      I18n.t(
        "sms_notification.recognized_you",
        sender: sender(recognition),
        url: recognition_url(recognition, url_opts)
      )
    end

    if recipient.last_sms_sent_at.nil?
      content += _("\nReply with STOP to opt out of additional messages")
    end

    content
  end
end
