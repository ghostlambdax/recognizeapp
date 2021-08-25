# frozen_string_literal: true

module Rewards
  module ProviderSyncDeviation
    class BaseDiscontinuanceHandler < BaseHandler
      def handle
        log "Handling discontinuance!"
        disable_object
        admin_notifier.notify
      end

      def disable_object
        log "Disabling #{stringified_object_type}(id: #{object.id})"
        object.update!(status: "disabled")
      end

      def stringified_object_type
        object.class.table_name.singularize.humanize.downcase
      end

      class NotificationDraper < SlackNotificationDraper
        def object_attributes_to_report
          raise NotImplementedError, "Subclasses must define this method."
        end

        def actions_taken_on_object
          raise NotImplementedError, "Subclasses must define this method."
        end

        def subject
          "A #{stringified_object_type} has been discontinued!"
        end

        def object_info
          object.attributes.slice(*object_attributes_to_report).map do |key, value|
            "_#{key.to_s.titleize}_: #{value}"
          end.push(*actions_taken_on_object).join("\n")
        end

        def blocks
          [
            section(text: ":information_source: *#{subject}* :information_source:"),
            divider,
            section(text: " *#{stringified_object_type.humanize}*:\n#{object_info}"),
            divider
          ]
        end
      end
    end
  end
end
