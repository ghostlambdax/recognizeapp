class SmsNotifier
  attr_reader :user, :message

  def self.send!(user, message)
    notification = new(user, message)
    notification.send! if notification.allowed_to_be_sent?
  end

  def initialize(user, message)
    @user = user
    @message = message
  end

  def allowed_to_be_sent?
    phone_is_valid?
  end

  def phone_is_valid?
    phone.present?
  end

  def phone
    user.phone
  end

  def send!
    Recognize::Application.twilio_client.send_sms(phone, message)
    user.update(last_sms_sent_at: DateTime.now)
  end
end
