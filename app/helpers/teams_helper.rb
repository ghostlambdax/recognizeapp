module TeamsHelper

  def favorite_team_tag(team_id, error_title=t("teams.cant_favorite_team"))
    opts = {
      wrapper_class: 'favorite-team',
      data: { team_id: team_id, error_title: error_title },
      disabled: current_user.user_team_ids.include?(team_id)
    }
    show_toggle(current_user.starred_team_ids.include?(team_id), tag(:span, class: 'checkmark'), opts)
  end

  def allow_teams?
    if current_user.present?
      return current_user.company.allow_teams? && feature_permitted?(:teams)
    else
      return false
    end
  end

  def favorite_joined_teams(user = current_user)
    user.favorite_joined_teams
  end

  def teams_without_favorites
    ids = favorite_joined_teams.map { |team| team[:id] }
    current_user.company.teams.where.not(id: ids).order("name asc")
  end

end
