class TeamAssignmentsController < ApplicationController
  def create
    current_user.add_team!(params[:team_id])
    head :ok
  end

  def destroy
  	current_user.remove_team!(params[:team_id])
  	head :ok
  end

  private
  def teams_params
    params[:user][:team_names]
  end
end