class IdentityProvidersController < ApplicationController
  enable_captcha only: [:show], if: Proc.new { |c| c.recaptcha_enabled_for_company?(c.params&.dig(:network)) }
  before_action :ensure_logged_out

  def show
    @user_session = UserSession.new(email: params[:email])
    @user_session.network = params[:network] # not mass assignable
  end

  private

  def ensure_logged_out
    if current_user.present?
      redirect_to authenticated_root_path
    end
  end
end
