class MobilePushListener

  def on_recognition_status_changed_to_approved(recognition)
    return unless recognition.approved?
    return if recognition.skip_notifications

    recognition.user_recipients.each do |recipient|
      RecognitionRecipientNotifier.notify(recognition, recipient)
    end
  end

  class RecognitionRecipientNotifier

    attr_reader :recognition, :recipient

    def self.notify(recognition, recipient)
      new(recognition, recipient).notify
    end

    def initialize(recognition, recipient)
      @recognition = recognition
      @recipient = recipient
    end

    def notify
      return unless has_all_credentials?
      RestClient.delay(queue: 'priority').post(PUSH_URL, payload.to_json, headers)
    end

    private
    PUSH_URL = "https://cp.pushwoosh.com/json/1.3/createMessage"

    def credentials
      Recognize::Application.config.rCreds["pushwoosh"]
    end

    def device_tokens
      @device_tokens ||= recipient.device_tokens.map(&:token)
    end

    def has_all_credentials?
      credentials.present? &&
      application_id.present? &&
      authorization_token.present? &&
      device_tokens.present?
    end

    def application_id
      credentials["application_code"]
    end

    def authorization_token
      credentials["token"]
    end

    def headers
      {
        :content_type => :json,
        :accept => :json
      }
    end

    def icon
      recognition.badge.permalink
    end

    def message
      "#{recognition.sender_name} #{I18n.t('dict.recognizes')} you!"
    end


    def payload
      {
        "request": {
          "application": application_id,
          "auth": authorization_token,
          "notifications": [{
            "send_date": "now",
            "ignore_user_timezone": true,
            "content": message,
            "devices": device_tokens,
            "link": recognition.permalink,
            "chrome_icon": icon,
            "firefox_icon": icon,
            "data": {
              "custom": attributes
            }
          }]
        }
      }
    end

    def ios_payload
      {
        ios_badges: 1,
        ios_sound: "ping.aiff",
        payload: attributes
      }
    end

    def android_payload
      {
        collapseKey: "foo",
        delayWhileIdle: true,
        timeToLive: 300,
        payload: attributes
      }
    end

    def attributes
      {
        action: "recognitions:show",
        id: recognition.recognize_hashid
      }
    end
  end
end
