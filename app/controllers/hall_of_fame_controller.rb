class HallOfFameController < ApplicationController
  filter_access_to :index, attribute_check: true, load_method: :current_user
  show_upgrade_banner only: [:index]

  def index
  end

  def current_winners
    @current_winners_groups = hall_of_fame.current_winners_grouped_by_period
    render partial: "current_winners"
  end

  def group_by_team
    @team = @company.teams.find(params[:team_id])
    render partial: "hall_of_fame_row", locals: { entity: 'team', entity_id: @team.id, time_period_groups: hall_of_fame.by_team }
  end

  def group_by_badge
    @badge = @company.company_badges.find(params[:badge_id])
    render partial: "hall_of_fame_row", locals: { entity: 'badge', entity_id: @badge.id, time_period_groups: hall_of_fame.by_badge }
  end

  private
  def hall_of_fame
    @hall_of_fame ||= HallOfFame.new(@company, current_user, params)
  end
  helper_method :hall_of_fame
  
  def user_map
    @user_map ||= @company.family_users(includes: :avatar).inject({}){|map,user| map[user.id] = user;map}
  end
  helper_method :user_map

end
