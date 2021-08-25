module Api
  module V2
    module Helpers
      module Tracking
        def track_request
          if defined?(Analytics) && defined?(current_user) && current_user.present?
            if current_user.kind_of?(Company)
              track_company_request
            else
              track_user_request
            end
          end
        rescue WineBouncer::Errors::OAuthUnauthorizedError => e
          Rails.logger.debug "Can't track api request. The user may have been deleted in this request. #{doorkeeper_access_token.application.name} - #{doorkeeper_access_token.id}"
        end

        def track_company_request
          company = current_user
          ::Analytics.track(
            user_id: "company-#{company.domain}", 
            event: "API: #{request.path}", 
            properties: {
              api: true,
              network: company.domain,
              admin_dashboard_enabled: company.allow_admin_dashboard,
              custom_badges: company.custom_badges_enabled?,
              has_subscription: company.subscription.present?,
              application_id: doorkeeper_access_token.id,
              application_name: doorkeeper_access_token.application.name
            })
        rescue => e
          opts = {message: "Failed tracking api request"}
          if defined?(company) && company.present?
            opts[:company] = company.id
            opts[:network] = company.domain
          end
          # ExceptionNotifier.notify_exception(e,opts)  
          Rails.logger.debug "Failed tracking api request: #{opts.inspect} - #{e.message}"          

        end

        def track_user_request
          ::Analytics.track(
            user_id: current_user.id, 
            event: "API: #{request.path}", 
            properties: {
              api: true,
              network: current_user.network,
              admin_dashboard_enabled: current_user.company.allow_admin_dashboard,
              custom_badges: current_user.company.custom_badges_enabled?,
              has_subscription: current_user.company.subscription.present?,
              application_id: doorkeeper_access_token.id,
              application_name: doorkeeper_access_token.application.name
            })
        rescue => e
          opts = {message: "Failed tracking api request"}
          if defined?(current_user) && current_user.present?
            opts[:current_user] = current_user.id
            opts[:network] = current_user.network
          end
          Rails.logger.debug "Failed tracking api request: #{opts.inspect} - #{e.message}"          
          # ExceptionNotifier.notify_exception(e,opts)  
        end
      end
    end
  end
end
Grape::Endpoint.send(:include, Api::V2::Helpers::Tracking)      
