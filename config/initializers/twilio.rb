module Recognize
  class Application

    class TwilioMockClient
      attr_reader :messages

      def lookup
        self
      end

      # The idea is to support usage like: 
      # number = Recognize::Application.twilio_client.lookup.phone_numbers(encoded_number).fetch
      # number.send(:phone_number)
      def phone_numbers(number)
        lookup = Struct.new(:number, :formatted_number) do
          def fetch
            OpenStruct.new(phone_number: formatted_number.phone_number)
          end
        end
        lookup.new(number, get(number))
      end

      def get(old_number)
        new_number = old_number.gsub(/[-()\s\.]/, '')

        if new_number =~ /[a-zA-Z]/
          # If the old_number contains a letter, simply return the old_number
          new_number = old_number
        elsif new_number[0] == '1'
          new_number = "+#{new_number}"
        elsif new_number[0..1] == '+1'
          # new_number = new_number
        elsif new_number[0] == '+'
          # new_number = new_number
        else
          new_number = "+1#{new_number}"
        end

        Hashie::Mash.new(phone_number: new_number)
      end

      def send_sms(phone, message)
        @messages ||= {}
        @messages[phone] ||= []
        @messages[phone] << message
        return true
      end

      def method_missing(*args, &block)

        return true
      end
    end

    def twilio_client
      return twilio_mock_client if Rails.env.test? || !Credentials.credentials_present?("twilio", ["sid", "token", "number"])
      Twilio::Client.new(
        Recognize::Application.config.rCreds["twilio"]["sid"],
        Recognize::Application.config.rCreds["twilio"]["token"],
        Recognize::Application.config.rCreds["twilio"]["number"]
      )
    end

    def twilio_mock_client
      @twilio_mock_client ||= TwilioMockClient.new
    end

    def twilio_test_client
      return TwilioMockClient.new unless Credentials.credentials_present?("twilio-test", ["sid", "token", "number"])
      Twilio::Client.new(
        Recognize::Application.config.rCreds["twilio-test"]["sid"],
        Recognize::Application.config.rCreds["twilio-test"]["token"],
        Recognize::Application.config.rCreds["twilio-test"]["number"]
      )
    end
  end
end
