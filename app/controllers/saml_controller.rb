class SamlController < ApplicationController
  include OauthConcern

  UnlinkedFbWorkplaceUserException = Class.new(Exception)

  skip_before_action :verify_authenticity_token, :only => [:acs, :logout]

  def index
    @attrs = {}
  end

  def sso

    if settings.nil? || !@company.saml_enabled?
      render :action => :no_settings
      return
    end


    request = OneLogin::RubySaml::Authrequest.new
    extra_params = {}

    # extra_params["RelayState"] = Base64.encode64(JSON.dump({close_on_open: true})) if params[:close_on_open]

    extra_params[:redirect] = params[:redirect] if params[:redirect].present?
    extra_params[:close_on_open] = params[:close_on_open] if params[:close_on_open].present?

    extra_params[:outlook_identity_token] = params[:outlook_identity_token] if params[:outlook_identity_token].present?

    if mobile_viewer?
      extra_params[:mobile] = 'true'
    end

    extra_params = {"RelayState" => Base64.encode64(JSON.dump(extra_params))} if extra_params.present?

    url = request.create(settings, extra_params)

    redirect_to(url)
  end

  def acs
    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], :settings => settings, :allowed_clock_drift => 2.seconds)

    if response.is_valid?
      handle_valid_saml_response(response)

    else
      logger.info "Response Invalid. Errors: #{response.errors}"
      @errors = response.errors
      render :action => :fail
    end
  end

  def metadata
    meta = OneLogin::RubySaml::Metadata.new
    render :xml => meta.generate(settings, true)
  end

  # Trigger SP and IdP initiated Logout requests
  def logout
    # If we're given a logout request, handle it in the IdP logout initiated method
    if params[:SAMLRequest]
      return idp_logout_request

    # We've been given a response back from the IdP
    elsif params[:SAMLResponse]
      return process_logout_response
    elsif params[:slo]
      return sp_logout_request
    else
      reset_session
    end
  end

  # Create an SP initiated SLO
  def sp_logout_request
    # LogoutRequest accepts plain browser requests w/o paramters

    if settings.idp_slo_target_url.nil?
      logger.info "SLO IdP Endpoint not found in settings, executing then a normal logout'"
      reset_session
    else

      # Since we created a new SAML request, save the transaction_id
      # to compare it with the response we get back
      logout_request = OneLogin::RubySaml::Logoutrequest.new()
      session[:transaction_id] = logout_request.uuid
      logger.info "New SP SLO for User ID: '#{session[:nameid]}', Transaction ID: '#{session[:transaction_id]}'"

      if settings.name_identifier_value.nil?
        settings.name_identifier_value = session[:nameid]
      end

      relayState = url_for controller: 'saml', action: 'index'
      redirect_to(logout_request.create(settings, :RelayState => relayState))
    end
  end

  # After sending an SP initiated LogoutRequest to the IdP, we need to accept
  # the LogoutResponse, verify it, then actually delete our session.
  def process_logout_response
    request_id = session[:transaction_id]
    logout_response = OneLogin::RubySaml::Logoutresponse.new(params[:SAMLResponse], settings, :matches_request_id => request_id, :get_params => params)
    logger.info "LogoutResponse is: #{logout_response.response.to_s}"

    # Validate the SAML Logout Response
    if not logout_response.validate
      error_msg = "The SAML Logout Response is invalid.  Errors: #{logout_response.errors}"
      logger.error error_msg
      render :inline => error_msg
    else
      # Actually log out this session
      if logout_response.success?
        logger.info "Delete session for '#{session[:nameid]}'"
        reset_session
      end
    end
  end

  # Method to handle IdP initiated logouts
  def idp_logout_request
    logout_request = OneLogin::RubySaml::SloLogoutrequest.new(params[:SAMLRequest], :settings => settings)
    if not logout_request.is_valid?
      error_msg = "IdP initiated LogoutRequest was not valid!. Errors: #{logout_request.errors}"
      logger.error error_msg
      render :inline => error_msg
    end
    logger.info "IdP initiated Logout for #{logout_request.nameid}"

    # Actually log out this session
    reset_session

    logout_response = OneLogin::RubySaml::SloLogoutresponse.new.create(settings, logout_request.id, nil, :RelayState => params[:RelayState])
    redirect_to logout_response
  end

  def complete
    @user = User.find_by(email: params[:user][:email], network: @company.domain)
    @user.validate_terms_and_conditions = true
    @user.first_name = params[:user][:first_name]
    @user.last_name = params[:user][:last_name]
    @user.terms_and_conditions = params[:user][:terms_and_conditions]

    if @user.save
      @user.verify_and_activate!
      redirect_url = params[:first_sso_login_for_user] == "true" ? welcome_url(network: @user.network) : origin_or_root
      sign_in_and_redirect(@user, redirect_url)
    else
      respond_with @user
    end
  end

  def idp_check
    idp_url = nil
    if current_user.present?
      # nil

    # if we're trying to do silent fb workplace login
    elsif params[:fb_workplace_params].present?
      idp_url = fb_workplace_silent_login_redirect_path

    elsif params[:ms_teams_params].present?
      idp_url = ms_teams_silent_login_redirect_path

    else
      # This whole method needs to be fast
      # Doing an OR condition on email and user_principal name will
      # likely be a slow query.
      # So for the majority of users who are not using UPN
      # don't query on upn. Only query for UPN if nothing comes up
      # under email.
      # The semantics of this are slightly different than doing an OR
      # The difference would arise in an edge case where a user has an
      # account with an email and a different account with the same value
      # as a UPN. Most people don't even have two accounts.

      scope = User.not_disabled.includes(company: :saml_configuration)

      accounts = User.none
      login_param = params[:email] # can be email or phone (or even #user_principal_name)
      if login_param.present?
        accounts = scope.where(email: login_param)

        if accounts.blank? && login_param.exclude?('@')
          # If an account is not found with an email, check see if users can be
          # found by phone. Any users who cannot be looked up by phone (according
          # to company.settings) is selected out of the accounts array.
          accounts = User.search_by_phone(login_param, scope)
        end

        # FIXME: this upn field doesn't seem to be accounted for in either account_chooser#show
        #        or (more importantly) during actual user_session creation (in User#find_by_login)
        if accounts.blank?
          accounts = scope.where(user_principal_name: login_param)
        end
      end

      opts = {email: login_param, token: params[:token]}
      opts[:redirect] = params[:redirect] if params[:redirect].present?
      opts[:outlook_identity_token] = params[:outlook_identity_token] if params[:outlook_identity_token].present?

      determine_idp_url = lambda { |company|
        idp_url = if params[:viewer].present?
          account_chooser_path(opts)
        elsif company.saml_enabled_and_forced?
          sso_saml_index_path(opts)
        else
          identity_provider_path(opts)
        end
      }

      if accounts && accounts.size > 1
        idp_url = account_chooser_path(opts)

      elsif accounts && accounts.size === 1 && accounts.first.network.present?
        account = accounts.first
        company = account.company

        opts[:network] = account.network
        determine_idp_url.call(company)

      elsif opts[:outlook_identity_token].present?
        company = Company.from_email(login_param)
        opts[:network] = company.domain
        determine_idp_url.call(company)

      else
        # nil
      end
    end

    render json: {idp_url: idp_url}
  rescue UnlinkedFbWorkplaceUserException => e
    render json: {message: "Please sync your account to Recognize. This window will close in a few moments and the Recognize bot will prompt you to complete linking your account."}

  rescue ArgumentError => e
    render json: {message: e.message}, status: 406
  end

  private

  def fb_workplace_silent_login_redirect_path
    raise ArgumentError.new("Missing fb workplace params") unless params[:fb_workplace_params].present?
    raise ArgumentError.new("Request is not properly signed") unless FbWorkplace::SignatureValidator.valid_signature?(params[:fb_workplace_params][:signed_request])

    fb_workplace_params = params[:fb_workplace_params]
    community_id = fb_workplace_params[:community_id]
    fb_workplace_user_id = fb_workplace_params[:psid]

    company = Company.joins(:settings).where(company_settings: {fb_workplace_community_id: community_id}).first
    unless company.present?
      if unclaimed_token = FbWorkplaceUnclaimedToken.where(community_id: community_id)
        msg = "Please complete the installation flow by typing 'Connect' in the Recognize chatbot."
      else
        msg = "We're sorry. We could not open this page. Please try to uninstall and reinstall the Recognize Workplace integration."
      end
      raise ArgumentError.new(msg)
    end

    user_with_linked_fb_account = company.users.where(fb_workplace_id: fb_workplace_user_id).first

    # if user, we don't have a session, but we've seen them before
    # so do silent login
    if user_with_linked_fb_account
      sign_in_user(user_with_linked_fb_account)
      return params[:redirect]

    # otherwise, no user, and need to link accounts
    else
      # post sync account button to chatbot
      easy_message = FbWorkplace::Webhook::EasyMessage.new(company, community_id, fb_workplace_user_id)
      easy_message.show_link_to_join_user_account(:welcome_for_first_time, {})

      # raise exception which should get caught in IdpRedirecter.js and show message
      raise UnlinkedFbWorkplaceUserException
    end
  end

  def ms_teams_silent_redirect_path
    raise ArgumentError.new("Missing ms teams params") unless params[:ms_teams_params].present?
    # Stubbing out for when SSO is in general availability in Teams
    raise "Not implemented yet"
  end

  def get_url_base
  "#{request.protocol}#{request.host_with_port}"
  end

  def handle_valid_saml_response(response)

    attributes = response.attributes
    response_params = {}

    if params[:RelayState].present?
      relay_gsubbed = params[:RelayState].gsub("\\r\\n", '')
      relay_params = JSON.parse(Base64.decode64(relay_gsubbed))
      if relay_params["outlook_identity_token"].present?
        response_params[:outlook_successful_auth] = true
      end
    else
      relay_params = {}
    end

    # `lambda` was chosen over `method` to encapsulate the logic to get redirect url, as creating a method didn't quite make
    # sense as the method wouldn't be generic in this controller's context.
    # User object is mutated a lot in the if-else block following the lambda; this makes redirect_url rather dynamic.
    get_redirect_url = lambda do |user|

      if relay_params['mobile'] == 'true'
        return get_mobile_redirect_url
      elsif relay_params['redirect']
        CGI.unescape(relay_params['redirect'])
      elsif relay_params["close_on_open"] || response_params[:outlook_successful_auth]
        response_params[:close_on_open] = relay_params["close_on_open"] ? true : false
        return user.first_sso_login? ?
                   welcome_url({network: user.network}.merge(response_params)) :
                   root_url(response_params)
      else
        return user.first_sso_login? ? welcome_url(network: user.network) : origin_or_root
      end
    end

    if @company.settings.auth_via_employee_id?
      return restrict_login!(I18n.t("activerecord.errors.models.company.blank_employee_id")) if response.nameid.blank?
      @user = User.find_by(employee_id: response.nameid, network: @company.domain)
    elsif @company.settings.auth_via_user_principal_name?
      @user = User.find_by(user_principal_name: response.nameid, network: @company.domain)
    else
      @user = User.find_by(email: response.nameid, network: @company.domain)
    end

    if @user && @user.first_name.present? && @user.last_name.present?
      redirect_url = get_redirect_url.call(@user)
      @user.touch(:last_auth_with_saml_at)
      if !@user.active? && !@user.disabled?
        @user.verify_and_activate!
      elsif @user.active? && !@user.verified?
        @user.verify!
      end
      @user.set_outlook_identity_token(relay_params["outlook_identity_token"])
      sign_in_and_redirect(@user, redirect_url)
    elsif @company.settings.auth_via_email?
      email = response.nameid
      first_name = attributes[@company.saml_configuration.first_name_uri] if @company.saml_configuration.first_name_uri.present?
      last_name = attributes[@company.saml_configuration.last_name_uri] if @company.saml_configuration.last_name_uri.present?

      user_creator = ExternalUserCreator.new(email: email, network: @company.domain, first_name: first_name, last_name: last_name, created_by: :saml)
      user_creator.create
      @user = user_creator.user

      if @user.persisted?
        @user.verify_and_activate!
        redirect_url = get_redirect_url.call(@user)
        @user.touch(:last_auth_with_saml_at)
        @user.set_outlook_identity_token(relay_params["outlook_identity_token"])

        if @user.first_name.present? && @user.last_name.present?
          sign_in_and_redirect(@user, redirect_url)
        else
          @first_sso_login_for_user = true # to be used in 'index' view for proper redirection.
          render action: "index"
        end
      else
        signup_restricted_error_message = I18n.t("activerecord.errors.models.company.signup_restricted")
        if @user.errors[:base].include?(signup_restricted_error_message)
          return restrict_login!(signup_restricted_error_message)
        else
          ExceptionNotifier.notify_exception(
            Exception.new("Failed SamlController#acs: #{controller_name}##{action_name}"),
            data: {user: @user.inspect, network: @company.domain, errors: @user.errors.inspect}
          )
          @errors = @user.errors.full_messages
          render :action => :fail
        end
      end
    else
      # if we end here, we are auth'ing via upn or employee 
      # AND don't have a fully provisioned user, so this isn't a supported use case
      # For UPN and employee id, user sync or sftp must provision accounts first before 
      # they can sign in.
      signup_restricted_error_message = I18n.t("activerecord.errors.models.company.employee_id_not_found")
      restrict_login!(signup_restricted_error_message)
    end
  end

  def settings
    @company.saml_settings
  end

  def restrict_login!(msg)
    signup_restricted_error_message = msg
    flash[:notice] = signup_restricted_error_message
    network = params[:network] || @company&.domain
    if network.present?
      redirect_to identity_provider_path(network: network)
    else
      redirect_to login_path
    end
  end
end
