module DuplicateRequestPreventer
  module Base
    extend ActiveSupport::Concern

    class_methods do
      def enable_duplicate_request_preventer
        self.class_eval do
          attr_accessor :request_form_id

          before_save { DuplicateRequestPreventer::Drp.prevent_duplicate_request(self) }
          # be defensive and delete key from the cache incase transaction is not successful
          after_rollback { DuplicateRequestPreventer::Drp.delete_key_from_cache(self) }
        end
      end
    end
  end
end
