# Example on how to get access token from authorization code:
# https://github.com/doorkeeper-gem/doorkeeper/wiki/Testing-your-provider-with-OAuth2-gem
# @code = "9bcee9e5698d6b9b86a5b5f9169caa2a3680556b1d1d9e5d574cb23381c777fe"#params[:code]
# @application = Doorkeeper::AccessGrant.includes(:application).joins(:application).where(token: @code).first.application
# @protocol = 'http://'#request.protocol
# @site = @protocol + Rails.application.config.host
# @client = OAuth2::Client.new(@application.uid, @application.secret, :site => @site)
# @token = @client.auth_code.get_token(@code, :redirect_uri => @application.redirect_uri)

Doorkeeper.configure do
  # Change the ORM that doorkeeper will use.
  # Currently supported options are :active_record, :mongoid2, :mongoid3, :mongo_mapper
  orm :active_record

  # This block will be called to check whether the resource owner is authenticated or not.
  resource_owner_authenticator do |routes|
    if user = User.find_by_id(session[:user_credentials_id])
      user
    else
      session[:return_to] = request.url
      redirect_to(login_url)
    end
  end

  resource_owner_from_credentials do
    app = Doorkeeper::Application.by_uid(params[:client_id])
    if app
       # manually inject secret into params server side so that Doorkeeper associates token with application
       # https://github.com/doorkeeper-gem/doorkeeper/issues/669#issuecomment-183771559
      user = User.find_by(email: params[:email].presence || params[:username].presence)
      user = user && user.valid_password?(params[:password]) ? user : nil
      user
    else
      nil
    end
  end

  # If you want to restrict access to the web interface for adding oauth authorized applications, you need to declare the block below.
  admin_authenticator do |routes|
    # Admin.find_by_id(session[:admin_id]) || redirect_to(new_admin_session_url)
    ((user = User.find_by_id(session[:user_credentials_id])) && user.admin?) ||
      redirect_to(login_url)
  end

  after_successful_authorization do |controller, context|
    if controller.request.params[:state]
      state = Base64.decode64(controller.request.params[:state])
      Rails.logger.debug "Doorkeeper#after_successful_authorization: #{state}"

      # state can be a string, number, or json
      # only handle parsable json
      state_params = JSON.parse(state) rescue nil

      if state_params
        token = context.issued_token
        if token
          u = User.find(token.resource_owner_id)
          c = u.company
          team_id = state_params['team_id']
          c.update_attribute(:microsoft_team_id, team_id) if team_id.present?
          Rails.logger.debug "Doorkeeper#after_successful_authorization: c:#{c.domain}, t:#{team_id}, u:#{c.id}"
        end
      end
    end
  end

  grant_flows %w(authorization_code client_credentials password)

  # Authorization Code expiration time (default 10 minutes).
  # authorization_code_expires_in 10.minutes

  # Access token expiration time (default 2 hours).
  # If you want to disable expiration, set this to nil.
  access_token_expires_in nil

  # Issue access tokens with refresh token (disabled by default)
  # use_refresh_token

  # Provide support for an owner to be assigned to each registered application (disabled by default)
  # Optional parameter :confirmation => true (default false) if you want to enforce ownership of
  # a registered application
  # Note: you must also run the rails g doorkeeper:application_owner generator to provide the necessary support
  # enable_application_owner :confirmation => false

  # Define access token scopes for your provider
  # For more information go to https://github.com/applicake/doorkeeper/wiki/Using-Scopes
  default_scopes  :profile, :read, :write
  optional_scopes :read, :write, :admin, :trusted, :company

  # Change the way client credentials are retrieved from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:client_id` and `:client_secret` params from the `params` object.
  # Check out the wiki for more information on customization
  # client_credentials :from_basic, :from_params

  # Change the way access token is authenticated from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:access_token` or `:bearer_token` params from the `params` object.
  # Check out the wiki for more information on customization
  access_token_methods :from_bearer_authorization, :from_access_token_param, :from_bearer_param

  # Change the test redirect uri for client apps
  # When clients register with the following redirect uri, they won't be redirected to any server and the authorization code will be displayed within the provider
  # The value can be any string. Use nil to disable this feature. When disabled, clients must provide a valid URL
  # (Similar behaviour: https://developers.google.com/accounts/docs/OAuth2InstalledApp#choosingredirecturi)
  #
  # test_redirect_uri 'urn:ietf:wg:oauth:2.0:oob'

  # Under some circumstances you might want to have applications auto-approved,
  # so that the user skips the authorization step.
  # For example if dealing with trusted a application.
  # skip_authorization do |resource_owner, client|
  #   client.superapp? or resource_owner.admin?
  # end

  #??WWW-Authenticate Realm (default "Doorkeeper").
  # realm "Doorkeeper"
end
