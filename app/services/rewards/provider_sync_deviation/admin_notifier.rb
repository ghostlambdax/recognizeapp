# frozen_string_literal: true

module Rewards
  module ProviderSyncDeviation
    class AdminNotifier
      attr_reader :subject, :notification_blocks, :destination_slack_channel

      def initialize(subject, notification_blocks, destination_slack_channel = nil)
        @subject = subject
        @notification_blocks = notification_blocks
        @destination_slack_channel = destination_slack_channel || default_destination_slack_channel
      end

      def notify
        ::Recognizebot.say(text: subject,
                           blocks: notification_blocks.to_json,
                           channel: destination_slack_channel)
      end

      def default_destination_slack_channel
        "#support-alerts"
      end
    end
  end
end
