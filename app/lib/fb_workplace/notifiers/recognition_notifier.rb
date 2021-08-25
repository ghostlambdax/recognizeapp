class FbWorkplace::Notifiers::RecognitionNotifier < FbWorkplace::Notifiers::BaseNotifier
  def notify!
    return if recognition.authoritative_company.settings.fb_workplace_token.blank?

    if recognition.fb_workplace_post_id.present?
      notify_sender
      post_back_to_workplace_post
    end

    super
  end

  def post_back_to_workplace_post
    company.fb_workplace_client.comment(recognition.fb_workplace_post_id, recognition.permalink)
  end

  def notify_sender
    return unless recognition.sender.fb_workplace_id.present?
    company.fb_workplace_client.send_message(recognition.sender.fb_workplace_id, message: {text: I18n.t('fb_workplace.recognition_sent')})
  end

  def notify_recipient(recipient)
    notify_recipient_user(recipient) if can_notify_recipient?(recipient)
    notify_manager(recipient, recipient.manager) if can_notify_recipient_manager?(recipient)
  end

  def notify_recipient_user(user)
    message = format_message(I18n.t('fb_workplace.you_been_recognized'), user)
    btns = share_buttons(:view, :share, :rewards)
    fb_client.send_message(user.fb_workplace_id, message: fb_client.group_button(message, btns))
  end

  def notify_manager(user, manager)
    message = I18n.t('fb_workplace.direct_report_recognized', full_name: user.full_name)
    btns = share_buttons(:view, :share)
    fb_client.send_message(manager.fb_workplace_id, message: fb_client.group_button(message, btns))
  end

  def can_notify_recipient?(recipient)
    recipient.fb_workplace_id.present?
  end

  def can_notify_recipient_manager?(recipient)
    recipient.manager.present? && 
    recipient.manager.fb_workplace_id.present? &&
    (recipient.manager.id != recognition.sender.id) &&
    recipient.manager.email_setting.receive_direct_report_peer_recognition_notifications?
  end
end
