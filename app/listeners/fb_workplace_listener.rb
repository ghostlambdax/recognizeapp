class FbWorkplaceListener

  def on_recognition_status_changed_to_approved(recognition)
    return unless recognition.approved?
    return if recognition.skip_notifications

    company = recognition.badge.company

    if company && company.fb_workplace_client.connected?
      FbWorkplace::Notifiers::BaseNotifier.delay(queue: 'priority').notify!(recognition.id)
    end
  end

end
