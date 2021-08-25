#http://localhost/callback#access_token=885691-oGToNjYIST1459INbO5Q
module OauthConcern
  include UrlHelper
  include EmailBlacklist
  include OauthHelper

  def finish_oauth
    set_authentication
    # Needs some test scripts to handle potential changes from
    # Omniauth gem

    # Having a multiple redirect error if this is
    # moved into a method or calling oauth_failure directly
    unless allow_login?
      flash[:error] = "Your company does not permit signing in with #{auth_method_title oauth_provider}"
      redirect_to auth_failure_path(strategy: oauth_provider) and return
    end

    if @authentication.present?
      handle_existing_authentication
    elsif current_user
      handle_existing_user
    else
      handle_new_user
    end
  end

  def email_tied_to_multiple_accounts?
    User.where(email: @oauth.email).size > 1 if @oauth.try(:email)
  end

  def handle_existing_authentication
    #update token if necessary
    # unless @authentication.credentials.present? and @authentication.credentials.token == @oauth.credentials.token
      @authentication.update(credentials: @oauth.credentials, extra: @oauth.extra)
      @authentication.user.apply_oauth(@oauth, build_authentications: false)
      @user = @authentication.user

      safe_oauth_user_save(@user)
    # end

    refresh_caches!(@user)

    if @user.first_name.blank? || @user.last_name.blank?
      render template: "saml/index"
    else
      flash[:notice] = "Your account has been successfully linked to Recognize."
      sign_in_and_redirect(@authentication.user)
    end
  end

  def handle_existing_user
    if @oauth.yammer? && (@oauth.uid.to_s != current_user.yammer_id.to_s)
      query_opts = { yammer_id: @oauth.uid }
      query_opts[:network] = chosen_network if chosen_network.present?
      user = User.where(query_opts).first
      return handle_new_user unless user
    else
      user = current_user
    end

    # protect against being logged in under one network, and oauth'ing for a user that doesn't have that domain in their networks
     # if !@oauth.yammer? || (@oauth.oauth.extra.raw_info.network_domains.kind_of?(Array) && @oauth.oauth.extra.raw_info.network_domains.include?(user.network))
      user.authentications.create!(:provider => @oauth.provider, :uid => @oauth.uid, :credentials => @oauth.credentials, :extra => @oauth.extra)

      # Applying oauth data can be tricky with existing users so,
      # for now, just allow syncing of google contacts with existing users
      user.apply_oauth(@oauth, build_authentications: false)
      safe_oauth_user_save(user)
      refresh_caches!(user)

    #   flash[:notice] = "Authentication successful."
    # else
    #     ExceptionNotifier.notify_exception(
    #       Exception.new("Yammer user does not belong to the currently logged in domain - Don't worry this was handled gracefully."),
    #       data: {current_user: user.id, network: user.network, yammer_domains: @oauth.oauth.extra.raw_info.network_domains.inspect})
    #     flash[:notice] = "We could not sign you in.  Your current yammer credentials do not belong to the current domain"

    # end
    if user.first_name.blank? || user.last_name.blank?
      go_to_saml(user)
    elsif user == current_user
      redirect_to origin_or_root
    else
      sign_in_and_redirect(user)
    end
  end

  def handle_new_user
    opts = chosen_network.present? ? {network: chosen_network } : {}
    user = User.find_or_create_by_oauth(@oauth, opts)

    user.skip_name_validation = true

    # not sure if its dangerous to add validate: false here
    # should be safe because we're only creating data from oauth
    # Had to add when adding phone from sync which, I tested,
    # and could contain an invalid phone number like: "+44 12312312"
    # which validates in O365 but does not validate against twilio which we validate on save
    # UPDATE: removing (validate: false)
    # because yammer users who were not in recognize were seeing errors
    # do to after_create callbacks being run but not having a company object? weird...
    if user.save
      user.verify_and_activate! unless user.disabled?

      User.delay(queue: 'priority_caching').sync_microsoft_graph_avatar(user.id) if @oauth.microsoft_graph?

      load_yammer_client(user)

      refresh_caches!(user)

      if user.first_name.blank? || user.last_name.blank?
        go_to_saml(user)
      else
        flash[:notice] = "Signed in successfully."

        redirect_path = (@oauth.try(:params) && @oauth.params["redirect"]) || welcome_path(network: user.network, refresh: true)
        sign_in_and_redirect(user, redirect_path)
      end
    else
      Rails.logger.warn "OAUTH: User authentication failed"
      if user.errors.count > 0
        Rails.logger.warn "OAUTH: errors: #{user.errors.full_messages.join(',')}"
        signup_restricted_error_message = I18n.t("activerecord.errors.models.company.signup_restricted")
        flash[:notice] = if user.errors[:base].include?(signup_restricted_error_message)
                           # Cherry pick this particular message, among possibly multiple error messages in `base`.
                           signup_restricted_error_message
                         else
                           "There was a problem signing you in.  Please try again."
                         end
      else
        Rails.logger.warn "OAUTH: failed but user has no errors"
        flash[:notice] = "We could not sign you in with those credentials.  Please try again."
        session[:omniauth] = @oauth.except('extra')
      end

      redirect_to login_path(popup: @oauth.params['popup'])
    end
  end

  def refresh_caches!(user)
    return unless Rails.env.production? # hack, but it really slows down dev
    SafeDelayer.delay(queue: 'caching').run(Company, user.company_id, :prime_caches!)
    SafeDelayer.delay(queue: 'caching').run(User, user.id, :prime_caches!)

    # user.company.delay(queue: 'caching').prime_caches!
    # user.delay(queue: 'caching').prime_caches!
  end

  def load_oauth
    @oauth = OauthService.new(request.env)
  end

  def chosen_network
    params[:network] || @oauth.params["network"] || current_user.try(:network)
  end

  def user_matches_oauth?
    if @oauth.yammer?
      return @oauth.uid == current_user.yammer_id
    end
    return true
  end

  # NOTE: sister method in OAuthConcern
  def mobile_viewer?
    if @oauth.present? && @oauth.params.present?
      Rails.logger.debug "OAUTH: mobile_viewer? @oauth.params.present? - true"
      Rails.logger.debug "OAUTH: mobile_viewer? params['mobile'] #{@oauth.params['mobile']} - #{params[:mobile]}"
      mobile_param =  @oauth.params['mobile'].present? ? @oauth.params['mobile'] : params[:mobile]
      viewer = @oauth.params['viewer'].present? ? @oauth.params['viewer'] : params[:viewer]
    else
      Rails.logger.debug "OAUTH: mobile_viewer? @oauth.params.present? - false"
      Rails.logger.debug "OAUTH: mobile_viewer? params:  - #{params[:mobile]} - #{params[:viewer]}"

      mobile_param = params[:mobile]
      viewer = params[:viewer]
    end

    (mobile_param == 'true') || (viewer == 'android') || (viewer == 'ios')
  end

  def oauth_safe_origin
    if @oauth && @oauth.origin
      og = Domainatrix.parse(@oauth.origin)
      if !["/login", "/user_sessions", "/auth/"].detect{|u| og.path.match(/#{u}/)} && og.host != 'login.microsoftonline.com'
        @oauth.origin
      end
    end
  end

  def origin_or_root
    oauth_redirect = @oauth ? @oauth.params["redirect"] : nil
    url = oauth_redirect || session[:return_to] || oauth_safe_origin || authenticated_root_path
    session[:return_to] = nil
    return url
  end

  def sign_in_user(user)
    user_session = UserSession.new(user, true)
    user_session.save!
    save_outlook_token(user_session.user)
  end

  def sign_in_and_redirect(user, url = origin_or_root)
    @user ||= user

    url = add_params_to_url(url, {outlook_successful_auth: true}) if @oauth && @oauth.params['popup'] && @oauth.params['popup'] == 'outlook'

    url = get_mobile_redirect_url if mobile_viewer?

    # if fb workplace token is in session, we've just added app
    # and are signing in.
    fb_workplace_sesh = FbWorkplace::SessionVars.new(user, session)
    if fb_workplace_sesh.should_handle?
      fb_workplace_sesh.assign_workplace_session_vars
      url = fb_workplace_sesh.redirect_url
    end

    if user.disabled?
      handle_disabled_user
    elsif !current_user || (current_user != user)
      begin
        sign_in_user(user)
      rescue Authlogic::Session::Existence::SessionInvalidError => e
        ExceptionNotifier.notify_exception(e, {data: {user: user, status: user.try(:status), disabled_at: user.try(:disabled_at)}})
        handle_disabled_user && return
      end
      ajax_safe_redirect(url)
    else
      # there is current user and I guess we are just refreshing auth
      # probably rare, but this is defensive, otherwise we render :create which
      # has no view template
      ajax_safe_redirect(url)
    end

  end

  def safe_oauth_user_save(user)
    # noticed that we could be oauth'ing from yammer and yammer doesn't validate phone number
    # so when we suck it in, and then save, we could get validation error
    # we don't want to bork oauth if this is the case
    begin
      user.save!
    rescue ActiveRecord::RecordInvalid => e
      ExceptionNotifier.notify_exception(e, {data: {user: user, also: "retrying without validation"}})
      user.save!(validate: false)
    end
  end

  def handle_disabled_user
    flash[:notice] = "Your account has been disabled. If you believe this to be an error, please contact your account administrator."
    url = new_user_session_path
    ajax_safe_redirect(url)
  end

  def get_mobile_redirect_url
    recognize_access_token = create_api_access_token
    "http://localhost/callback#access_token=#{recognize_access_token.token}"
  end

  def handle_mobile_login
    ajax_safe_redirect get_mobile_redirect_url
  end

  def create_api_access_token
    @user = @user || @user_session.user
    # FIXME: make this more robust

    application = Doorkeeper::Application.where(name: "Recognize Mobile App").first
    access_token = Doorkeeper::AccessToken.create!(
      application_id: application.id,
      resource_owner_id: @user.id,
      scopes: application.scopes.to_s
    )
    return access_token
  end

  def save_outlook_token(user)
    if @oauth.present? && @oauth.params.present? && @oauth.params["outlook_identity_token"].present? && user
      user.set_outlook_identity_token(@oauth.params["outlook_identity_token"])
    end
  end

  def go_to_saml(user)
    @user = user
    save_outlook_token(user)
    render template: "saml/index"
  end

  def set_authentication
    auth_query_params = { provider: @oauth.provider, uid: @oauth.uid }
    auth_query_params[:users] = {network: chosen_network} if chosen_network.present?

    @authentication = Authentication
      .joins(:user)
      .where(auth_query_params)
      .first
  end

  def allow_login?
    email = @oauth.oauth_provider.email
    return false if email.blank?

    user_params = { email: email }
    # Ensure that get user from correct network
    user_params[:network] = chosen_network if chosen_network.present?

    company = User.find_by(user_params).try(:company) || Company.find_by(domain: Mail::Address.new(email).domain)
    # Only return Company with domain users if blacklisted email
    company = Company.find_by(domain: "users") if company.blank? && blacklisted_email?(email)

    # if we can't find the company based upon user's email
    # then its likely that the company doesn't exist
    # and this is a first time login and account creation
    # therefore, we should allow
    return true if company.blank?

    case oauth_provider.to_sym
    when :google_oauth2
      company.try(:allow_google_login)
    when :yammer
      company.try(:allow_yammer_connect)
    when :microsoft_graph
      company.try(:allow_microsoft_graph_oauth)
    else
      false
    end
  end

  def oauth_provider
    @authentication.try(:provider) || @oauth.try(:provider) || request.env["omniauth.strategy"].name
  end
end
