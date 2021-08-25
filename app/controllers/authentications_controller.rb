# frozen_string_literal: true

class AuthenticationsController < ApplicationController
  include OauthConcern

  before_action :load_oauth, except: [:failure, :new]

  def index
    @authentications = current_user.authentications if current_user
  end

  def new
    # params[:redirect] is being whitelisted in ApplicationController#reject_improper_redirect_params (which is needed to prevent redirection vulnerabilities).
    redirect_to (params[:redirect] || authenticated_root_path) and return if current_user.present?
    @auth_service = OauthService::BaseProvider.factory(Hashie::Mash.new({provider: params[:provider]}))
    raise ActionController::RoutingError.new('Not Found') unless @auth_service.present?
  end

  def create
    if email_tied_to_multiple_accounts? && @oauth.params["network"].blank? && !current_user # dont prompt to choose account if logged in
      session[:oauth] = @oauth
      redirect_to account_chooser_path(email: @oauth.email, oauth: true, mobile: @oauth.params["mobile"])
    else
      finish_oauth
    end
  end

  def destroy
    @authentication = current_user.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = "Successfully destroyed authentication."
    redirect_to authentications_url
  end

  def oauth_failure
    # p = Rails.application.routes.recognize_path(request.path)
    omniauth_strategy_name = request.env['omniauth.error.strategy'].name

    if params[:error] == "access_denied"
      flash[:error] = "You have denied access to Recognize from #{omniauth_strategy_name.to_s.titleize}.  Please create an account or try to login again."
    end

    Rails.logger.warn "--- OAUTH Failure ---"
    Rails.logger.warn request.env.keys.grep(/omniauth/).map{|k| "#{k} - #{request.env[k]}" }.join("\n")
    Rails.logger.warn "--- OAUTH Failure(end) ---"

    redirect_to auth_failure_path(strategy: omniauth_strategy_name) and return
  end

  def failure
  end

  def setup
    # request.env['omniauth.strategy'].options[:origin] = request.referer
    request.env['omniauth.strategy'].options[:scope] =  params[:scope] if params[:scope].present?
    render plain: "Setup complete.", status: 200
  end

  def auth_status
    json = if current_user
      {status: true, user_id: current_user.recognize_hashid}
    else
      {status: false, user_id: nil}
    end
    render json: json.as_json
  end
end
