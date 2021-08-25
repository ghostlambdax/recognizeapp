class FbWorkplace::Notifiers::AnniversaryNotifier < FbWorkplace::Notifiers::BaseNotifier
  
  def notify_recipient(recipient)
    recipient_notifier(recipient).notify
  end

  def recipient_notifier(recipient)
    RecipientNotification.new(self, recipient)
  end

  class RecipientNotification
    attr_reader :notifier, :recipient, :manager

    delegate :recognition, :share_buttons, :fb_client, :format_message, to: :notifier
    delegate :badge, to: :recognition

    def initialize(notifier, recipient)
      @notifier = notifier
      @recipient = recipient
      @manager = recipient.manager
    end

    def notify
      notify_recipient if can_notify_recipient?
      notify_manager if can_notify_manager?
    end

    def notify_recipient
      fb_client.send_message(recipient.fb_workplace_id, message: fb_client.group_button(recipient_text, share_buttons(:view, :share, :rewards)))
    end

    def notify_manager
      fb_client.send_message(manager.fb_workplace_id, message: fb_client.group_button(manager_text, share_buttons(:view, :share)))
    end

    def can_notify_manager?
      can_notify_manager = false

      if manager.present?
        if badge.birthday?
          can_notify_manager = manager.email_setting.receive_direct_report_birthday_notifications?
        else
          can_notify_manager = manager.email_setting.receive_direct_report_anniversary_notifications?
        end
      end

      can_notify_manager && manager.fb_workplace_id.present?
    end

    def can_notify_recipient?
      recipient.fb_workplace_id.present?
    end

    def description
      badge.anniversary_message
    end

    def recipient_text
      msgs = []
      msgs << format_message("#{title}. #{description}", recipient)
      if recipient_wants_private_recognition?
        # These are using the same localization key
        # but will leave for possible future use
        msgs << nil # adds newline
        if badge.birthday?
          msgs << I18n.t('fb_workplace.employee_anniversary_privacy')
        else
          msgs << I18n.t('fb_workplace.employee_anniversary_privacy')
        end
      end

      msgs.join("\n")
    end

    def manager_text
      msgs = []
      msgs << I18n.t('fb_workplace.manager_text', title: title, full_name: recipient.full_name)

      if badge.birthday? && recipient_wants_private_recognition?
        msgs << nil #adds newline
        msgs << I18n.t('fb_workplace.manager_birthday_privacy')
      elsif recipient_wants_private_recognition?
        msgs << nil #adds newline
        msgs << I18n.t('fb_workplace.manager_anniversary_privacy')
      end

      msgs.join("\n")
    end

    def recipient_wants_private_recognition?
      if badge.birthday?
        recipient.receive_birthday_recognitions_privately?
      else
        recipient.receive_anniversary_recognitions_privately?
      end
    end

    def share_permitted?
      super && !recipient_wants_private_recognition?
    end
  
    def title
      badge.short_name
    end

  end

end
