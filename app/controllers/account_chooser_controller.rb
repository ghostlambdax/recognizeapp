class AccountChooserController < ApplicationController
  include OauthConcern
  include PasswordResetConcern

  before_action :require_login_param, unless: ->{ current_user.present? && switching_accounts? }
  skip_before_action :ensure_correct_company, only: [:update], if: :switching_accounts?
  
  def show
    handle_mobile_login if current_user.present? && mobile_viewer?

    login_param = params[:email] || current_user&.email ||  current_user&.phone # can be email or phone
    scope = User.not_disabled
    @accounts = scope.where(email: login_param)

    if @accounts.blank? && login_param.present?
      if login_param.include?('@')
        # initialize new user if there exists a company for the user's domain
        company = Company.from_email(login_param)
        if company&.persisted?
          @accounts = [User.new(email: login_param, network: company.domain, company: company)]
        end
      else
        @accounts = User.search_by_phone(login_param, scope)
      end
    end

    @user_session = UserSession.new(email: login_param)
  end

  def update
    @params = params
    @user = User.find_by(email: params[:email], network: params[:network])
    if @user.nil?
      formatted_phone = Twilio::PhoneNumber.format(params[:email]) || params[:email]
      @user = User.find_by(phone: formatted_phone, network: params[:network])
    end

    if @user.blank?
      company = Company.from_email(params[:email])
      @user = User.new(email: params[:email], network: company.domain, company: company) if company&.persisted?
    end


    if params[:outlook_identity_token].present?
      decoder = Recognize::OutlookJwtDecoder.new(params[:outlook_identity_token])
      decoder.validate
      if decoder.valid? && @user.present?
        outlook_user = User.where(network: params[:network], outlook_identity_token: decoder.unique_id).first
        if outlook_user.present? && !outlook_user.disabled?
          sign_in_and_redirect(outlook_user, params[:redirect])
          return
        end
      end
    end


    if @user && @user.disabled?
      handle_disabled_user
      return
    elsif saved_oauth = session.delete(:oauth)
      @oauth = saved_oauth
      finish_oauth
      return
    elsif params[:pw_reset].present?
      handle_password_reset
      return
    end

    # we're choosing another account to login as. 
    # So, pre-emptively log out of this one.
    if switching_accounts?
      UserSession.destroy_session_and_cookies!(UserSession.find, session)
    end
  end

  private
  def switching_accounts?
    params[:switch_accounts] == "true"
  end

  def require_login_param
    redirect_to root_path if params[:email].blank?
  end

end
