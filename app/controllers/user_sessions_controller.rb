class UserSessionsController < ApplicationController
  include OauthConcern
  enable_captcha only: [:create], if: Proc.new { |c| c.recaptcha_enabled_for_company?(c.params&.dig(:user_session, :network)) }

  def new
    @user = User.new
    # NOTE: if this needs to be standardized to user_sessions[email]
    #       this is currently being set by SamlController#idp_check when
    #       user doesn't exist
    @user_session = UserSession.new(email: params[:email])
  end

  def session_scope
    user_params = user_session_params

    @company.users
  end

  def create
    if user_session_params && user_session_params[:network]
      @company = Company.find_by(domain: user_session_params[:network])

      UserSession.with_scope(find_options: session_scope, id: nil) do
        @user_session = UserSession.new(user_session_params)
      end
    else
      @user_session = UserSession.new(user_session_params)
    end
    if verify_recaptcha(model: @user_session) && @user_session.save
      @user = @user_session.user
      @user.set_outlook_identity_token(user_session_params[:outlook_identity_token]) if user_session_params[:outlook_identity_token].present?

      fb_workplace_sesh = FbWorkplace::SessionVars.new(@user, session)

      if fb_workplace_sesh.should_handle?
        fb_workplace_sesh.assign_workplace_session_vars
        ajax_safe_redirect fb_workplace_sesh.redirect_url

      elsif session[:return_to].present?
        ajax_safe_redirect session.delete(:return_to)
      elsif params[:redirect].present?
        ajax_safe_redirect CGI.unescape(params[:redirect])
      else
        if request.xhr?
          if mobile_viewer?
            handle_mobile_login
          else
            opts = {refresh: true}
            opts[:outlook_successful_auth] = true if outlook_popup?
            respond_with @user, location: authenticated_root_url(opts)
          end
        else
          redirect_back_or_default authenticated_root_url
        end
      end
    else
      if request.xhr?
        respond_with @user_session
      else
        if user_session_params && user_session_params[:network].present?
          @user = User.where(email: @user_session.email, network: user_session_params[:network]).first
        else
          @user = User.where(email: @user_session.email).first
        end
        render :action => 'new'
      end
    end
  end

  def destroy
    email = current_user&.email
    phone = current_user&.phone
    company = current_user&.company
    user_identifier = email.present? ? email : phone
    @user_session = UserSession.find
    UserSession.destroy_session_and_cookies!(@user_session, session)
    flash[:notice] = "Successfully logged out."

    # MS Teams?
    url = if ms_teams_viewer?
        if URI.parse(request.referer).path == "/ms_teams/tab_config"
          ms_teams_tab_config_path(entity_id: params[:entity_id])
        else
          ms_teams_tab_placeholder_path(entity_id: params[:entity_id])
        end
      # Outlook?
      elsif outlook_viewer? && !popup?
        outlook_addin_path(logout: true)
      elsif current_user.present?
        identity_provider_path(network: current_user.network)
      else
        root_path
      end
    redirect_to url
  end

  def ping
    if current_user
      response = {status: true}
    else
      response = {status: false}
    end
    render json: response.to_json
  end

  private

  def user_session_params
    params[:user_session].permit(:email, :password, :network, :outlook_identity_token).to_h if params[:user_session]
  end

end
