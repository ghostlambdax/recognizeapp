# frozen_string_literal: true

module MsTeamsHelper
  def ms_teams_auth_placeholder(&block)
    render layout: "ms_teams/authentication_placeholder" do
      capture(&block) if current_user.present?
    end
  end

  def ms_team_tab_choices
    [[t("ms_teams.tab_config.tab_choice.all_recognitions"), stream_url(entity_id: nil)]] + current_user.company.teams.map{|t| [t.name, stream_url(team_id: t.recognize_hashid, entity_id: nil)]}
  end

  def ms_teams_tab_choice_options
    options_for_select(ms_team_tab_choices, @tab_config.tab_choice)
  end

  def ms_teams_tab_choice_url(tab_config)
    return user_path(current_user) if ms_teams_personal_tab?

    choice = tab_config.tab_choice
    opts = { network: params[:network] }

    if ms_teams_viewer?
      opts.merge!(viewer: "ms_teams", entity_id: tab_config.entity_id)
    end

    if :recognitions == choice.to_sym
      stream_url(opts)
    elsif :redemptions == choice.to_sym
      redemptions_url(opts)
    else
      uri = Addressable::URI.parse(choice)
      uri.query_values = (uri.query_values || {}).merge(opts)
      uri.to_s
    end
  end

  def ms_teams_configurable_tab?
    ms_teams_viewer? && !ms_teams_personal_tab? && ms_teams_entity.present? && ms_teams_entity.tab_choice.present?
  end

  def ms_teams_entity
    return nil unless params[:entity_id]
    @entity ||= MsTeamsConfig.where(entity_id: params[:entity_id]).first
  end

  def ms_teams_on_tab_choice_page?
    return false unless ms_teams_entity.present?
    uri = Addressable::URI.parse(ms_teams_entity.tab_choice)
    current_page? uri.path
  end
end
