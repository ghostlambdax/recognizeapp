module DuplicateRequestPreventer
  class Drp
    class << self
      def prevent_duplicate_request(record)
        return unless record.valid?
        return if record.request_form_id.blank?

        request_key = get_cache_key(record)

        if duplicate_request?(request_key)
          record.errors.add(:base, error_message) # needed for JsonResource
          throw(:abort)
        else
          cache_request_form_id(request_key)
        end
      end

      def cache_request_form_id(request_key)
        Rails.logger.info("Writing to cache: #{request_key}")
        Rails.cache.write(request_key, true, expires_in: 15.minutes)
      end

      def delete_key_from_cache(record)
        return if record.request_form_id.blank?

        request_key = get_cache_key(record)
        Rails.logger.info("Releasing the cached request-form-id: #{request_key}")
        Rails.cache.delete_matched(request_key)
      end

      def duplicate_request?(request_key)
        Rails.logger.info("Fetching from cache: #{request_key}")
        if Rails.cache.exist?(request_key)
          Rails.logger.warn('*** Caught duplicate request ***')
          return true
        end

        return false
      end

      def error_message
        I18n.t('forms.duplicate_submission')
      end

      def get_cache_key(record)
        "#{record.class.to_s}#save-request-#{record.request_form_id}"
      end
    end
  end
end
