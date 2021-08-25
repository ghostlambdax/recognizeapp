# handle passing token through session
class FbWorkplace::SessionVars
  include UrlHelper

  attr_reader :user, :company, :session, :params

  def initialize(user, session)
    @user = user
    @company = user.company
    @session = session
    @org_install = false

    if session[:fb_workplace_params]
      @params = ActionController::Parameters.new(JSON.parse(Base64.decode64(session[:fb_workplace_params]))) rescue nil
    end
  end

  def assign_workplace_session_vars
    return unless params.present?
    return unless self.should_assign?
    
    # this used to be an || condition
    # However, there was a bug when community id was there but we were just doing followup action
    # when user was linking account, and not installing and thus resetting token
    if params[:fb_workplace_token].present? && params[:fb_workplace_community_id].present?
      @org_install = true
      FbWorkplaceUnclaimedToken.where(community_id: params[:fb_workplace_community_id]).destroy_all
      company.assign_fb_workplace_community_and_token!(params[:fb_workplace_community_id], params[:fb_workplace_token])
    end

    if params[:fb_workplace_sender_id].present?
      user.update_column(:fb_workplace_id, params[:fb_workplace_sender_id])
    end

    do_follow_up_action
    # show_carousel if params[:fb_workplace_post_id].present?

  rescue => e
    ExceptionNotifier.notify_exception(e)
  ensure
    session.delete(:fb_workplace_params)
  end

  def do_follow_up_action
    if params[:fb_workplace_class].blank?
      return
    end

    klass = params[:fb_workplace_class].classify.constantize rescue nil
    action = params[:fb_workplace_action]
    klass.send(action, params) if action.present?
  end

  def show_carousel
    community_id = self.company.settings.fb_workplace_community_id
    sender_id = self.user.fb_workplace_id
    post_id = params[:fb_workplace_post_id]

    FbWorkplace::Webhook::Page::Mention.show_carousel({fb_workplace_community_id: community_id, fb_workplace_sender_id: sender_id, fb_workplace_post_id: post_id})
  end

  def redirect_url
    return test_redirect_url if Rails.env.test?

    common_opts = {host: Rails.application.config.host, protocol: "https"}
    if user_is_in_proper_account?
      Rails.application.routes.url_helpers.workplace_start_url(common_opts.merge({success: true, refresh: true, org_install: @org_install}))
    elsif UserSession.find
      Rails.application.routes.url_helpers.workplace_failure_url(common_opts.merge({network: params[:network], wrong_network: true}))
    else
      Rails.application.routes.url_helpers.identity_provider_url(common_opts.merge({network: params[:network], fb_workplace_network: false}))
    end

  end

  # There's not really any way around this
  # Tests need relative paths, but the app needs absolute fqdn urls
  # Perhaps there is a better way to stub this in a test, but whatevs for now
  def test_redirect_url
    common_opts = {}
    if user_is_in_proper_account?
      Rails.application.routes.url_helpers.workplace_start_path(common_opts.merge({success: true, refresh: true}))
    elsif UserSession.find
      Rails.application.routes.url_helpers.workplace_failure_path(common_opts.merge({network: params[:network], wrong_network: true}))
    else
      Rails.application.routes.url_helpers.identity_provider_path(common_opts.merge({network: params[:network], fb_workplace_network: false}))
    end
  end

  def should_assign?
    should_handle? && user_is_in_proper_account?
  end

  def should_handle?
    !user.disabled? && params.present? && params["fb_workplace_community_id"].present?    
  end

  def update_url(url)
    return add_params_to_url(url, {fb_workplace_success_auth: true})
  end

  def user_is_in_proper_account?
    return true if params["fb_workplace_token"].present? #don't care about network when installing
    user.company.try(:settings).try(:fb_workplace_community_id) == params["fb_workplace_community_id"]
  end
end