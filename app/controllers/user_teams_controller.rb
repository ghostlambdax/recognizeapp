class UserTeamsController < ApplicationController
  def create
    user.teams.add(team) if team.valid?
    render json: { user_id: user.id, team: team, errors: team.errors }, status: team.valid? ? 200 : 422
  end

  def destroy
    user.teams.remove(team)
    head :ok
  end

  private

  def user
    @user ||= company.users.find(params[:user_id])
  end

  def team
    @team ||= begin
      company.teams.find_or_initialize_by(id: params[:team_id]) do |new_team|
        new_team.name = params[:team_name]
      end
    end
  end

  def company
    @company
  end
end
