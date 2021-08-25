# frozen_string_literal: true

class UserSession < Authlogic::Session::Base
  include Rails.application.routes.url_helpers

  record_selection_method :find_by_login # in models/user.rb

  attr_accessor :network
  same_site "None"

  validate :check_if_verified
  validate :check_not_disabled
  after_save :set_first_login_at

  disable_magic_states true
  generalize_credentials_error_messages I18n.t('login.login_password_error')

  def self.login_as!(user)
    user.reset_persistence_token!
    UserSession.create!(user)
  end

  def self.destroy_session_and_cookies!(user_session, env_session)
    user_session.destroy if user_session
    env_session.delete(:user_credentials_id)
    env_session.delete(:email)
    env_session.delete(:superuser)
    env_session.delete(:fb_workplace_params)
    env_session.delete(:email_network)    
  end
  private

  def set_first_login_at
    attempted_record.update_attribute(:first_login_at, Time.now) unless attempted_record.first_login_at.present?
  end

  # taken from http://www.nathancolgate.com/post/184694426/adding-email-and-user-verification-to-authlogic
  def check_if_verified
    return unless attempted_record
    return if attempted_record.verified? || attempted_record.active?

    link = "<a class='button button-small' href='#{resend_verification_email_path(email: attempted_record.email)}'>#{I18n.t('forgot_password.resend_verification_email')}</a>".html_safe
    errors.add(:base, I18n.t('activerecord.errors.models.user_session.not_verified_email_html', link: link))
  end

  def check_not_disabled
    return unless attempted_record.try(:disabled_at)

    errors.add(:base, I18n.t('activerecord.errors.models.user_session.account_disabled'))
  end
end
