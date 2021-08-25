class PasswordResetsController < ApplicationController
  include PasswordResetConcern

  before_action :load_user_using_perishable_token, :only => [:edit, :update]
  before_action :choose_account, only: [:create], if: :account_needs_to_be_chosen?
  before_action :set_referrer_and_network_data_in_session, only: [:new]
  before_action :set_network_param_from_session, only: [:create]

  def index
    redirect_to new_password_reset_path
  end

  def new
  end

  def create
    session.delete(:network_for_resend_verification)
    handle_password_reset
  end

  def edit
  end

  def update
    @user.password = params[:user][:password]
    @user.skip_original_password_check = true
    @user.force_password_validation = true
    @user.skip_name_validation = true

    if @user.disabled?
      flash[:error] = "We cannot reset your password because your account has been disabled. If you believe this to be in error, please contact support@recognizeapp.com"
      render :action => :edit

    elsif @user.save
      #TODO: abstract and move all this to a model...

      #the forgot password flow can also serve as email verification for all users except first user
      @user.verify_and_activate!

      Rails.logger.debug "Resetting password for: #{@user.inspect}"
      UserSession.login_as!(@user.reload)
      flash[:notice] = "Password successfully updated"

      fb_workplace_sesh = FbWorkplace::SessionVars.new(@user, session)
      if fb_workplace_sesh.should_handle?
        fb_workplace_sesh.assign_workplace_session_vars
        url = fb_workplace_sesh.redirect_url
      else
        url = root_url
      end

      redirect_to url

    else
      flash[:error] = "There was a problem updating your password"
      render :action => :edit
    end
  end


protected

private
  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])
    # @user = User.where(perishable_token: params[:id]).first
    unless @user
      flash[:notice] = "This verification link has expired, please resubmit the password reset form."
      redirect_to new_password_reset_path
    end
  end

  def choose_account
    redirect_to account_chooser_path({ email: params[:email], pw_reset: params[:pw_reset] })
  end

  def set_referrer_and_network_data_in_session
    session[:network_for_resend_verification] = referrer_path_parameters[:network] if referrer_path_parameters[:network].present?
    session[:url_before_resending_verification_email] = return_url_after_form_submission
  end

  def account_needs_to_be_chosen?
    params[:network].blank? && session_network_for_resend_verification.nil? && users_from_params_email.size > 1
  end

  def users_from_params_email
    return [] unless params[:email].present?

    users = User.where(email: params[:email])
    return users if users.present?
    User.search_by_phone(params[:email])
  end

  def set_network_param_from_session
    params[:network] = session_network_for_resend_verification if session_network_for_resend_verification.present?
  end

  def session_network_for_resend_verification
    session[:network_for_resend_verification]
  end

  def referrer_recognizeapp?
    return false unless request.referrer.present?

    URI.parse(request.referrer).host.ends_with?('recognizeapp.com')
  end

  def return_url_after_form_submission
    return request.referrer if(referrer_path_parameters[:controller] != 'password_resets' && referrer_recognizeapp?)

    current_user.present? ? new_recognition_path(network: current_user.network) : login_path
  end

  def referrer_path_parameters
    Rails.application.routes.recognize_path(request.referrer)
  end
end
