# frozen_string_literal: true

MS_TEAMS_CONTEXT_KEYS = ["locale", "theme", "entityId", "subEntityId", "isFullScreen", "sessionId", "chatId", "hostClientType", "tenantSKU", "jsonTabUrl", "userLicenseType", "appSessionId", "isTeamArchived", "teamType", "userTeamRole", "channelRelativeUrl", "channelId", "channelName", "channelType", "defaultOneNoteSectionId", "groupId", "teamId", "teamName", "teamSiteUrl", "teamSiteDomain", "teamSitePath", "ringId", "tid", "loginHint", "upn", "userPrincipalName", "userObjectId"]

class MsTeamsController < ApplicationController
  PERSONAL_TAB_ENTITY_ID = "recognize-personal"

  skip_before_action :verify_authenticity_token, only: [:auth, :tab_config, :connector_config]
  before_action :require_ms_teams_user, except: [:auth, :signup, :start]
  before_action :ensure_company_has_tab_installed, only: [:tab_placeholder], unless: :ms_teams_personal_tab?
  layout :determine_layout

  def auth
  end

  def auth_complete
  end

  def tab_config
    @tab_config = @company.ms_teams_configs.for_entity(params[:entity_id]) if current_user
  end

  def connector_config
  end

  # Keeping it light here with a single endpoint
  # for getting and setting tab or connector config settings
  def settings
    config = current_user.company.ms_teams_configs.for_entity(params[:entity_id])
    if request.delete?
      config.destroy!
      head :ok
    elsif request.post?
      # this should always save, so hard fail if it doesn't
      config.update!(config_settings)
      head :ok
    else
      render json: config.as_json
    end
  end

  # Signup page in a popup
  def signup
  end

  # Landing page for admin configuration shown when logged out
  # As compared to #tab_placeholder which is the placeholder for the actual tab for all users
  def start
  end

  def tab_placeholder
    @tab_config = @company.ms_teams_configs.for_entity(params[:entity_id]) if current_user
  end

  private
  def config_settings
    params.permit(settings: [:contentUrl, :entityId, :selectedTab, :websiteUrl, :removeUrl, :suggestedDisplayName, context: MS_TEAMS_CONTEXT_KEYS])
  end

  OVERLAY_LAYOUT_ACTIONS = [:auth_complete, :start, :tab_config, :tab_placeholder]
  def determine_layout
    if OVERLAY_LAYOUT_ACTIONS.include?(action_name.to_sym)
      "ms_teams_overlay"
    elsif action_name == 'signup'
      "application"
    else
      nil
    end
  end

  def require_ms_teams_user
    return false if params[:action] == "tab_config" && params[:removeTab] == "true"

    unless current_user
      if ms_teams_viewer?
        redirect_to ms_teams_start_path(redirect: url_for(only_path: true, entity_id: params[:entity_id]))
      else
        # FIXME: maybe there is a better path.
        #        This should only be hit if end user clicks "Go to website" when logged out
        #        See more in NOTE in tab_placeholder.html.erb
        redirect_to microsoft_teams_employee_recognition_path
      end
    end
  end

  def ensure_company_has_tab_installed
    unless current_user.company.ms_teams_configs.where(entity_id: params[:entity_id]).exists?
      render "no_tab_settings"
      # need to manually call this method from ApplicationController
      # Because this trips up the normal filter chain and thus won't be called
      # unless its explicit here
      allow_iframe
    end
  end
end
