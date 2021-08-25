require_relative 'point_activity/recorder'
require_relative 'point_activity/destroyer'

class RecognitionObserver < ActiveRecord::Observer
  def after_update(recognition)
    after_status_changed_to_approved(recognition) if recognition.status_changed_to_approved?
  end

  def after_create(recognition)
    after_status_changed_to_approved(recognition) if recognition.status_changed_to_approved?
  end

  def after_status_changed_to_approved(recognition)
    return unless recognition.status_changed_to_approved?

    PointActivity::Recorder.record!(recognition)
    recognition.update_earned_points
    refresh_cached_user_graph_for(recognition.sender)

    recognition.recognition_recipients.each do |rr|
      if rr.team_id.present?
        after_recognition_approved_for_team(recognition, Team.find(rr.team_id))
      elsif rr.company_id.present?
        after_recognition_approved_for_company(recognition, Company.find(rr.company_id))
      end

      after_recognition_approved_for_user(recognition, rr.user)
    end
  end

  def after_destroy(recognition)
    PointActivity::Destroyer.destroy!(recognition) if recognition.approved?
    refresh_cached_user_graph_for(recognition.sender)

    recognition.recognition_recipients.each do |r|
      send("after_destroy_for_#{r.class.to_s.downcase}", recognition, r)
    end
  end

  protected

  def refresh_cached_user_graph_for(user)
    user.delay(queue: 'caching').refresh_cached_user_graph!
  end

  def after_recognition_approved_for_user(recognition, user)
    refresh_cached_user_graph_for(user)

    return if recognition.badge.ambassador?
    return if recognition.skip_notifications

    if user.active?
      RecognitionNotifier.delay(queue: 'priority').new_recognition_for_user(recognition, user)
    else
      if recognition.cross_company?(user)
        RecognitionNotifier.delay(queue: 'priority').invite_from_crosscompany_recognition_for_user(recognition, user)
      else
        RecognitionNotifier.delay(queue: 'priority').invite_from_recognition_for_user(recognition, user)
      end
    end
  end

  def after_recognition_approved_for_company(recognition, company)
    # Note: The method `RecognitionNotifier.new_recognition_for_company` being called below seems to have been commented
    # out in the source file back in 2014 (and is therefore not available). Hence, make this method a no-op, but keep it
    # for reference purpose.
    return # no-op

    return if recognition.skip_notifications
    RecognitionNotifier.new_recognition_for_company(recognition, company)
  end

  # Disabled method note (Dec'18)
  # This method, as seen below, does not send any emails, because all active members are included in the `user_recipients` array.
  # NOTE: This method is called for each team recipient. (this previously caused duplicate emails)
  def after_recognition_approved_for_team(recognition, team)
    return if recognition.skip_notifications

    # team.users.active.each do |user|
      # RecognitionNotifier.delay(queue: 'priority').new_recognition_for_team(recognition, team, user) unless recognition.user_recipients.include?(user)
    # end
  end

  def after_destroy_for_company(recognition, company)
  end

  def after_destroy_for_user(recognition, user)
    refresh_cached_user_graph_for(user)
  end

  def after_destroy_for_team(recognition, team)
    raise "not implemented!"
  end
end
