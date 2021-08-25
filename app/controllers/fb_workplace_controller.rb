class FbWorkplaceController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:callback, :deauth]

  def start

  end

  def callback
    token = FbWorkplace::AccessToken.new(params[:code])
    Rails.logger.debug "Install code: #{params[:code]}" if Rails.env.development?

    if token.valid?
      client = FbWorkplace::Client.new(token)
      community_id = client.community_id
      if current_user
        current_user.company.assign_fb_workplace_community_and_token!(community_id, token)

        redirect_to params[:redirect_uri] || workplace_start_path(success: true, org_install: true)
      else
        unclaimed_token = FbWorkplaceUnclaimedToken.find_or_initialize_by(community_id: community_id)
        unclaimed_token.token = token.to_s
        unclaimed_token.save

        # This is the same code that is SignupsController#fb_workplace
        # be sure to update in both places        
        fb_workplace_params = {
          fb_workplace_token: token.to_s,
          fb_workplace_community_id: community_id
        }
        session[:fb_workplace_params] = Base64.encode64(fb_workplace_params.to_json)

        # If we redirect right away to the redirect_uri - the window will close (intended behavior)
        # redirect_to fb_workplace_signups_path(referrer: "fb_workplace", org_install: true)
        # redirect_to "https://work.workplace.com/work/install_done_redirect/"
        redirect_to params[:redirect_uri] || fb_workplace_signups_path(referrer: "fb_workplace", org_install: true)
      end
    else
      render plain: "Error finding token: #{token.to_s}", status: 400
    end

  end

  def failure
    if params[:wrong_network].present?
      @error = I18n.t('fb_workplace.logged_in_wrong_network')
    else
      @error = I18n.t('fb_workplace.unknown_failure')
    end
  end

  def deauth
    FbWorkplace::Logger.log "deauth requests should be handled by webhook, not fb_workplace_controller"
    head :bad_request
  end

end
