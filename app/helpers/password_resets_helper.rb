module PasswordResetsHelper
  def options_for_password_reset
    if request.path == "/resend_verification_email"
      {
        pw_reset: 'false',
        page_title: t('forgot_password.resend_verification_email'),
        description: t('forgot_password.description'),
        title: t('forgot_password.resend_verification_email'),
        button_text: t('forgot_password.send_email')
      }
    else
      {
        pw_reset: 'true',
        page_title: t('password_resets.title'),
        description: t('password_resets.description'),
        title: t('forgot_password.title'),
        button_text: t('forgot_password.reset_my_password')
      }
    end
  end
end
