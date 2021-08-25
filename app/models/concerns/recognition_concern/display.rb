module RecognitionConcern
  module Display
    extend ActiveSupport::Concern

    def permalink(opts={})
      recognition_url(self, host: Recognize::Application.config.host, protocol: Recognize::Application.config.web_protocol)
    end

    def badge_permalink(size=200, protocol="")
      self.badge.permalink(size, protocol)
    end

    def badge_name
      self.badge.short_name
    end

    def system_recognition?
      self.badge.system?
    end

    def recipients_label
      self.flattened_recipients.collect{|r| r.full_name}.to_sentence
    end

  end
end