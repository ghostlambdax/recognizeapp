# frozen_string_literal: true

# Notes for adding a new event listener
# - The relevant object's class needs to be added to the WebhookListener's subscribe :scope as well
#   in config/initializers/wisper.rb
#
module Webhook
  class Listener
    # Note: this event is NOT published in case of auto-approval (to be consistent with redemption's behavior)
    def on_recognition_pending(recognition)
      recognition.authoritative_company&.deliver_webhook_event('recognition_pending', recognition)
    end

    def on_recognition_status_changed_to_approved(recognition)
      return unless recognition.approved?

      recognition.authoritative_company&.deliver_webhook_event('recognition_approved', recognition)
    end

    def on_redemption_pending(redemption)
      redemption.company&.deliver_webhook_event('redemption_pending', redemption)
    end

    def on_redemption_approved(redemption)
      return unless redemption.approved?

      redemption.company&.deliver_webhook_event('redemption_approved', redemption)
    end
  end
end
