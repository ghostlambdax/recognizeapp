# app/services/recognition_async_service.rb
class RecognitionAsyncService
  include Wisper::Publisher
  attr_reader :recognition_id

  def initialize(recognition_id)
    @recognition_id = recognition_id
  end

  def recognition
    @recognition ||= Recognition.find(@recognition_id)
  end

  def signature(method_name, args)
    "RecognitionAsyncService##{method_name}-#{@recognition_id}"
  end

  def call_after_create(user_recipients_attrs = {})
    ensure_recipients_have_company_id_set
    handle_recognitions_for_new_users(user_recipients_attrs)
  end

  def send_notifications(opts = {})
    publish_recognition_status_changed_to_approved
    notify_managers
    notify_managers_in_yammer
    post_message_to_yammer(group_id_to_post_to: opts[:post_to_yammer_group_id]) unless recognition.is_private?
  end

  def update_counter_caches
    update_user_recognitions_counter_cache
    update_company_last_recognition_created_at
    reset_sent_recognitions_counter_due_to_bug_in_rails
  end

  # note: this method hasn't been coalesced into :call_after_create
  #       because this is invoked on :after_commit, as opposed to :after_create
  #       also, :send_notifications is invoked on :after_commit, but only when approved; opposite of what is needed here
  def publish_recognition_pending
    publish(:recognition_pending, recognition)
  end

  private

  def update_user_recognitions_counter_cache
    recognition.send(:update_user_recognitions_counter_cache)
  end

  def handle_recognitions_for_new_users(user_recipients_attrs)
    if sender_not_system_user?
      recognition.user_recipients.each do |r|
        if r.pending_signup_completion? or r.invited_from_recognition?
          if user_recipients_attrs.dig(r.id, :skip_name_validation)
            r.skip_name_validation = true
          end
          recognition.sender.invite_from_recognition!(r, recognition)
        end
      end
    end
  end

  # This ensures that attribute is saved before the point calculation code in `update_user_recognitions_counter_cache`.
  def ensure_recipients_have_company_id_set
    recognition.recognition_recipients.each do |rr|
      rr.update_column(:recipient_company_id, rr.user.company_id) if rr.recipient_company_id.blank?
    end
  end

  def update_company_last_recognition_created_at
    unless recognition.sender.system_user?
      recognition.authoritative_company.update_attribute(:last_recognition_sent_at, Time.now)
      recognition.user_recipients.each do |user|
        user.company.update_attribute(:last_recognition_received_at, Time.now)
      end
    end
  end

  def reset_sent_recognitions_counter_due_to_bug_in_rails
    # REMOVE ME when this bug is fixed:
    # https://github.com/rails/rails/issues/13304
    Company.delay(queue: 'priority_caching').reset_counters(recognition.sender_company_id, :sent_recognitions)
  end

  def publish_recognition_status_changed_to_approved
    publish(:recognition_status_changed_to_approved, recognition)
  end

  def notify_managers
    return if recognition.team_recipients.present? || recognition.skip_notifications
    return if recognition.from_bulk
    return if recognition.pending_approval?
    recognition.send(:user_recipients_with_managers).each do |user|
      managers = if recognition.authoritative_company.allow_manager_of_manager_notifications?
                   user.hierarchical_managers(depth: 2)
                 else
                   [ user.manager ]
                 end

      managers.each do |manager|
        next if manager.id == recognition.sender_id
        setting = recognition.send(:get_relevant_manager_notification_setting)
        accepts_email = setting && manager.accepts_email?(setting)
        next unless accepts_email

        UserNotifier.delay(queue: 'priority').manager_notifier(manager.id, user.id, recognition.sender.id, recognition.id)
      end
    end
  end

  def notify_managers_in_yammer
    msg_template = "%user% has been recognized with the #{recognition.badge.short_name} badge."
    recognition.user_recipients.each do |recipient|
      msg = msg_template.gsub("%user%", recipient.full_name)
      begin
        YammerManagerNotifier.delay(queue: 'priority').notify!(recipient.id, msg, recognition.yammer_og_object)
      rescue => e
        ExceptionNotifier.notify_exception(e)
      end
    end
  end

  def post_message_to_yammer(group_id_to_post_to: )
    recognition.delay(queue: 'priority').post_to_yammer_wall!(group_id_to_post_to: group_id_to_post_to)
  end


  def sender_not_system_user?
    !recognition.sender.system_user?
  end
end
