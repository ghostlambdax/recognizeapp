module Api
  module V2
    module XAuthEmail

      def self.extended(base)
        Api::V2::Helpers::CoreHelpers.send(:include, InstanceMethods)
      end

      def x_auth_email(opts = {})
        api_class_setting(:x_auth_email, opts)
        route_setting(:x_auth_email, opts)
      end

      def x_auth_network(opts = {})
        api_class_setting(:x_auth_network, opts)
        route_setting(:x_auth_network, opts)
      end

      module InstanceMethods
        def x_auth_email
          route_setting(:x_auth_email) || {required: true}
        end

        def x_auth_network
          route_setting(:x_auth_network) || {required: true}
        end
      end
    end
  end
end
