# frozen_string_literal: true

module Rewards
  module ProviderSyncDeviation
    class BaseHandler
      attr_reader :object

      def self.handle(object_id)
        new(object_id).handle
      rescue StandardError => e
        ExceptionNotifier.notify_exception(e, data: {handler: self.name, object: "#{object.class}(id: #{object.id})"})
      end

      def initialize(object_id)
        @object = object_klass.find(object_id)
      end

      def object_klass
        raise NotImplementedError, "Subclasses must define this method."
      end

      def handle
        raise NotImplementedError, "Subclasses must define this method."
      end

      def admin_notifier
        AdminNotifier.new(admin_notification.subject, admin_notification.blocks)
      end

      def admin_notification
        self.class::NotificationDraper.new(self)
      end

      private

      def log(msg)
        Rails.logger.debug "[#{self.class.name}][#{object.class}(id: #{object.id})][#{caller[0].gsub(Rails.root.to_s, '')}] #{msg}"
      end
    end
  end
end
