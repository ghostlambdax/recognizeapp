module RecognitionConcern
  module Notification
    extend ActiveSupport::Concern

    private

    def get_relevant_manager_notification_setting
      return nil unless self.sender and self.badge

      setting = nil

      if self.sender.system_user?
        if self.badge.is_anniversary?
          setting = if self.badge.birthday?
                      :receive_direct_report_birthday_notifications
                    else
                      :receive_direct_report_anniversary_notifications
                    end
        else # skip the initial ambassador badge
        end
      else
        setting = :receive_direct_report_peer_recognition_notifications
      end

      setting
    end
  end
end