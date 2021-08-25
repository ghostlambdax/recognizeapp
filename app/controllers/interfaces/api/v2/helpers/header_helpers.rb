module Api
  module V2
    module Helpers
      module HeaderHelpers
        def ensure_auth_headers_on_swagger_route(*headers)
          routes = Api::V2::Base.combined_namespace_routes.map{|name,routes| routes}.flatten
          if routes.present?
            routes.each do |r| 
              route_options = r.instance_variable_get("@options")
              # If route has not specified, default to setting the header(this is only run if token does not have resource_owner_id set)
              # If route has specified required, use that setting
              # Can also specify that the header is optional
              if !route_options[:settings].has_key?(:x_auth_email) || route_options[:settings][:x_auth_email][:required] || route_options[:settings][:x_auth_email][:optional]
                route_options[:params]["X-Auth-Email"] ||= { description: 'Email of user to act as', in: :header, name: "X-Auth-Email", type: "String"} if headers.include?(:email)
              end

              if !route_options[:settings].has_key?(:x_auth_network) || route_options[:settings][:x_auth_network][:required] || route_options[:settings][:x_auth_network][:optional]
                route_options[:params]["X-Auth-Network"] ||= { description: 'Network of acting user', in: :header, name: "X-Auth-Network", type: "String"} if headers.include?(:network)
              end

            end
          end  
        end

        # FIXME: dry me up
        def ensure_no_email_auth_headers_on_swagger_route
          routes = Api::V2::Base.combined_namespace_routes.map{|name,routes| routes}.flatten
          if routes.present?
            routes.each do |r| 
              route_options = r.instance_variable_get("@options")
              route_options[:params] ||= {}
              route_options[:params].delete("X-Auth-Email")
              route_options[:params].delete("X-Auth-Network")              
            end
          end  
        end
      end
    end
  end
end
Grape::Endpoint.send(:include, Api::V2::Helpers::HeaderHelpers)      