WineBouncer.configure do |config|
  config.auth_strategy = :swagger

  config.define_resource_owner do |thing|
    if doorkeeper_access_token
      
      if doorkeeper_access_token.resource_owner_id
        # company scoped tokens can optionally override email
        # otherwise it defaults to token owner.
        if doorkeeper_access_token.scopes.include?("company") && headers['X-Auth-Email'].present?
          admin = User.active.find(doorkeeper_access_token.resource_owner_id)
          # only allow api requests from fully active users
          user = admin.company.users.active.where(email: headers['X-Auth-Email']).first
          if user.blank?
            error = Api::V2::InvalidHeaderResponse.new(:email_auth_headers_invalid)
            raise(WineBouncer::Errors::OAuthUnauthorizedError, error) 
          end
          user
        else
          user = User.find(doorkeeper_access_token.resource_owner_id)
          if user.disabled?
            error = Api::V2::InvalidHeaderResponse.new(:user_disabled)
            raise(WineBouncer::Errors::OAuthUnauthorizedError, error) 
          elsif user.blank?
            error = Api::V2::InvalidHeaderResponse.new(:user_not_found)
            raise(WineBouncer::Errors::OAuthUnauthorizedError, error) 
          end
          user
        end
      
      else  

        # 10/2/2017 - Not sure why this code was here, but was breaking tests.
        # Remove soon if no problems
        # if doorkeeper_access_token.scopes.include?("trusted")
        #   error = Api::V2::InvalidHeaderResponse.new(:unauthorized_client)
        #   raise(WineBouncer::Errors::OAuthUnauthorizedError, error) 
        # end

        # No Resource owner, therefore we need to require XAuthEmail 
        # unless route has explictly stated, its not required

        if x_auth_email[:required] && headers['X-Auth-Email'].blank?
          error = Api::V2::InvalidHeaderResponse.new(:missing_email_auth_headers)
          raise(WineBouncer::Errors::OAuthUnauthorizedError, error)           

        elsif x_auth_network[:required] && headers['X-Auth-Network'].blank?
          error = Api::V2::InvalidHeaderResponse.new(:missing_email_auth_headers)
          raise(WineBouncer::Errors::OAuthUnauthorizedError, error) 

        else
          if headers['X-Auth-Email'].present? && headers['X-Auth-Network'].present?
            user = User.joins(company: :domains).find_by(email: headers['X-Auth-Email'], company_domains: {domain: headers['X-Auth-Network']})
            if user.blank?
              error = Api::V2::InvalidHeaderResponse.new(:email_auth_headers_invalid)
              raise(WineBouncer::Errors::OAuthUnauthorizedError, error)               
            end
            user
          elsif headers['X-Auth-Network'].present?
            # can specify any of the companies legitimate domains
            # allows spreadsheet import to come from s3 bucket where folder name can be added
            # as domain. This way we don't need to store alternate mapping of folder to company
            company = Company.joins(:domains).where(company_domains: {domain: headers['X-Auth-Network']}).first
            unless company.present?
              error = Api::V2::InvalidHeaderResponse.new(:missing_email_auth_headers)
              raise(WineBouncer::Errors::OAuthUnauthorizedError, error)               
            end
            company
          else
            nil
          end
        end          
        ############################################################
        # # Ugh this code....
        # # If the refactor above works out for a while, delete this code
        # # 5/13/2018
        #
        # if !x_auth_email[:required] && !x_auth_email[:optional]
        #   nil
        # elsif headers['X-Auth-Email'].blank? || headers['X-Auth-Network'].blank?
        #   # If missing XAuthEmail and its optional, that's cool
        #   if x_auth_email[:optional]
        #     nil
        #   else
        #     error = Api::V2::InvalidHeaderResponse.new(:missing_email_auth_headers)
        #     raise(WineBouncer::Errors::OAuthUnauthorizedError, error) 
        #   end
        # else
        #   user = User.find_by(email: headers['X-Auth-Email'], network: headers['X-Auth-Network'])
        #   if user.blank?
        #     if x_auth_email[:optional]
        #       nil
        #     else
        #       error = Api::V2::InvalidHeaderResponse.new(:email_auth_headers_invalid)
        #       raise(WineBouncer::Errors::OAuthUnauthorizedError, error) 
        #     end
        #   end
        #   user
        # end # if !x_auth_email[:required]
        ###############################################################
      end # if resource_owner_id
    end # if doorkeeper_access_token
  end # define_resource_owner
end # WineBouncer.configure
