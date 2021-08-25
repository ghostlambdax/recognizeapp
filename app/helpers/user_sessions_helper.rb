module UserSessionsHelper

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user(refresh=false)
    return @current_user if defined?(@current_user) && !refresh
    return @current_user.reload if refresh
    @current_user = current_user_session && current_user_session.user
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      if @company && @company.saml_enabled_and_forced?
        redirect_to sso_saml_index_path(network: @company.domain)
      elsif @company.present?
        redirect_to identity_provider_path(network: @company.domain)
      else
        redirect_to login_path
      end
    end
  end

  def require_no_user
    if current_user
      logout_current_user
      return true
    end
  end

  def store_location(url=nil)
    # do not store ajax or non GET requests
    url ||= request.fullpath if request.get? && !request.xhr?
    session[:return_to] = url
  end

  def back_or_default_url(url_default=nil)
    url = session[:return_to] || url_default || root_path
    session[:return_to] = nil
    return url
  end

  def redirect_back_or_default(url_default=nil)
    url = back_or_default_url(url_default)
    ajax_safe_redirect url
  end

  def logout_current_user
    logger.info "logout_current_user"
    current_user_session.destroy if current_user_session
    clear_session
    @current_user = nil
  end

  def clear_session
    logger.info "clear_session"
    #clear all but return_to
    tmp = session[:return_to]
    session.clear
    session[:return_to] = tmp
  end

  def require_http_auth_user
    authenticate_or_request_with_http_basic do |username, password|
      username == "brandid" && password == "asdf"
    end
  end

end
