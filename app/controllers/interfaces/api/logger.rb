module Api
  class Logger
    def initialize(app)
      @app = app
    end

    def call(env)
      payload = {
        remote_addr:    env['REMOTE_ADDR'],
        request_method: env['REQUEST_METHOD'],
        request_path:   env['PATH_INFO'],
        request_query:  env['QUERY_STRING'],
        x_auth_email: env['HTTP_X_AUTH_EMAIL'],
        x_auth_network: env['HTTP_X_AUTH_NETWORK'],
        headers1: env['AUTHORIZATION'],
        headers2: env['HTTP_AUTHORIZATION']
      }

      ActiveSupport::Notifications.instrument "grape.request", payload do
        @app.call(env).tap do |response|
          if env["api.endpoint"].params.present? 
            payload[:params] = env["api.endpoint"].params.to_hash
            payload[:params]["password"] = "<filtered>"
            payload[:params].delete("route_info")
            payload[:params].delete("format")
          end
          payload[:response_status] = response[0]
          Rails.logger.debug "API REQUEST: #{payload}"
        end
      end
    end
  end
end