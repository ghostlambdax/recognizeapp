module Api
  module V2
    module Helpers
      module CoreHelpers
        
        def ok
          case self.status
          when 200, 201, 202, 204, 205, 206
            "success"
          else
            "error"
          end
        end

        def present(object, options = {})

          response = case object
          when Doorkeeper::OAuth::ErrorResponse
            raise WineBouncer::Errors::OAuthUnauthorizedError, object
          when Doorkeeper::AccessToken
            entity = endpoint_entity
            options[:with] ||= entity if entity
            options[:params] ||= entity.documentation if entity
            super(:ok, self.ok)
            super(:type, "AccessToken")
            super(:token, object.token) if options[:include_token]
            super(object, options)  

          when ActiveRecord::Base
            raise ActiveRecord::RecordInvalid, object if object.respond_to?(:errors) && object.errors.present?
            entity = endpoint_entity
            options[:with] ||= entity if entity
            options[:params] ||= entity.documentation if entity
            options[:current_user] = current_user unless options[:skip_current_user]
            super(:ok, self.ok)
            super(:type, object.class.to_s)
            # key = object.class.to_s.downcase.to_sym
            # super(key, object, options.merge(:except =>[:ok, :type]))
            super(object, options)

          when Array, Enumerable, ActiveRecord::Relation
            entity = endpoint_entity
            options[:with] ||= entity if entity
            options[:params] ||= entity.documentation if entity
            options[:current_user] = current_user
            super(:ok, self.ok)
            super(:type, "Collection")
            super(:page, object.current_page)
            super(:count, object.length)
            super(:total_pages, object.total_pages)
            super(:total_count, object.total_entries)

            # key = entity.parent.to_s.demodulize.downcase.to_sym
            # super(key, object, options)
            super(object, options)

          when TrueClass
            message = options[:message]
            super({message: message})
            super(:ok, self.ok)
            super(:type, "Success")

          when Symbol
            payload = options[object]
            super({object => payload})
            super(:ok, self.ok)
            super(:type, "Object")
            super(:key, object)

          when NilClass
            raise ActiveRecord::RecordNotFound
          else
            raise "Unsupported return object type: #{object}"
          end

        end

        def endpoint_entity
          for_klass = self.options[:for]
          if for_klass.present? && for_klass.respond_to?(:const_defined?)
            return for_klass.const_get(:Entity) if for_klass.const_defined?(:Entity)
          end
        end

        def unhash(hashed_value)
          Recognize::Application.hasher.decode(hashed_value).presence
        end

        def doorkeeper_application_label
          token = self.doorkeeper_access_token
          app = token.application
          "#{app.id}-#{app.name}"
        end

        def api_viewer_attributes
          { viewer: "api_v2", viewer_description: self.doorkeeper_application_label }
        end

      end
    end
  end
end
