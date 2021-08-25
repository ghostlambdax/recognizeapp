module LinksHelper
  # generate an invite link if crypted_password is not present, else generate a password-reset link

  # host should be explicitly mentioned here because it is not available within classes like BulkMailerForm
  def invite_or_password_reset_link(user, host: Recognize::Application.config.host)
    if user.crypted_password.blank?
      # invite links are not supposed to expire with time(in this case),
      # so we don't check the time-validity of the perishable_token here
      user.reset_perishable_token! if user.perishable_token.blank?
      if user.company.saml_enabled_and_forced?
        sso_saml_index_url(network: user.company.domain, host: host)
      else
        verify_signup_url(user.perishable_token, host: host)
      end
    else
      # on the other hand password-reset links are supposed to expire with time(default being 10 mins),
      # so we also check the time-validity of the perishable_token here
      user.reset_perishable_token! unless User.find_using_perishable_token(user.perishable_token)
      edit_password_reset_url(user.perishable_token, host: host)
    end
  end
end
