module PasswordResetConcern
  def handle_password_reset

    medium = looks_like_email?(params[:email]) ? :email : :phone
    @user = if current_user.present?
              current_user
            else
              User.find_by_login(params[:email], params[:network])
            end
    path = return_url_after_form_submission if params[:set_referrer].to_s.downcase == 'true'
    notice = if @user
      if @user.company.disable_passwords?
        path = identity_provider_path(network: @user.network)
        "Passwords have been disabled as per your company policy."
      elsif password_reset_form?
        # We should always reset the token here if the user has requested a reset. 
        # This specifically protects against user lockout if the token has expired
        # Without this, there would be no way to regenerate a new unexpired token. 
        @user.reset_perishable_token!
        @user.deliver_password_reset_instructions!(medium, edit_password_reset_url(@user.perishable_token))
        I18n.t("forgot_password.instruction_email")
      else
        if @user.email.present?
          UserNotifier.verification_email(@user).deliver_now
        end

        if medium == :phone && @user.phone.present?
          SmsNotifierJob.perform_now(@user.id, I18n.t("sms_notification.verify_account", url: verify_signup_url(@user.perishable_token)))
        end

        current_user.present? ? I18n.t('forgot_password.verification_email_for_logged_in_user') : I18n.t('forgot_password.verification_email')
      end
    else
      if password_reset_form?
        I18n.t('forgot_password.instruction_email')
      else
        I18n.t('forgot_password.verification_email')
      end
    end

    flash[:notice] = notice
    path ||= fallback_redirect_path
    ajax_safe_redirect path
  end

  private

  def looks_like_email?(string)
    string&.match(/@/)
  end

  def password_reset_form?
    params[:pw_reset] == 'true'
  end

  def fallback_redirect_path
    if previous_referrer_url.present? && previous_referrer_url != root_url
      previous_referrer_url(true)
    else
      params[:network] ? identity_provider_path(network: params[:network]) : login_path
    end
  end

  def previous_referrer_url(parse_and_delete_from_session = false)
    key = :url_before_resending_verification_email
    parse_and_delete_from_session ? session.delete(key) : session[key]
  end
end
