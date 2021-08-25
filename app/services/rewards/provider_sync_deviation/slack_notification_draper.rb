# frozen_string_literal: true

module Rewards
  module ProviderSyncDeviation
    class SlackNotificationDraper < SimpleDelegator
      def initialize(obj)
        super
      end

      def section(text:, text_type: "mrkdwn")
        {
          "type": "section",
          "text": {
            "type": text_type,
            "text": text
          }
        }
      end

      def divider
        {
          "type": "divider"
        }
      end
    end
  end
end
