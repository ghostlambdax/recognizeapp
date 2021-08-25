# frozen_string_literal: true

class SmsNotifierJob < ApplicationJob
  def perform(user_id, message_body)
    @user = User.find(user_id)
    @message_body = message_body
    if @user.last_sms_sent_at.nil?
      I18n.with_locale(@user.locale) do
        @message_body += _("\nReply with STOP to opt out of additional messages")
      end
    end

    send!
  end

  def named_job_arguments(job_arguments, hash)
    user_id = job_arguments[0]
    user = User.find(user_id)
    hash[:user_id] = user.id
    hash[:company_id] = user.company_id
    return hash
  end

  def signature
    # Job id is always included so that this is always unique
    # and bypasses duplicate checking
    "SmsNotifierJob-#{@company_id}-#{@user_id}-#{self.job_id}"
  end

  private

  def send!
    begin
      SmsNotifier.send!(@user, @message_body)
    rescue => e
      ExceptionNotifier.notify_exception(e, {data: {user: @user, message: @message_body}})
    end
  end
end
