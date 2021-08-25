class TeamManagement::BaseController < ApplicationController
  before_action :set_team, only: [:edit, :update]
  filter_access_to :edit, :update, :show, :destroy, attribute_check: true

  # BEWARE: this is for DeclarativeAuthorization functionality...
  #               we need it so DA knows which model to load
  #               for attribute checking
  #               don't know if this will conflict with anything else...
  #               woa...
  def self.controller_name
    "team"
  end

  private
  def set_team
    @team = @company.teams.find_from_recognize_hashid(params[:team_id])
  rescue ActiveRecord::RecordNotFound => e
    # FIXME: This is buggy
    #   For html format, it causes broken redirect inside the user picker modal
    #   For JS format, it does not show flash message after redirection (due to being handled by Turbolinks)
    flash[:error] = "Sorry, that team does not exist."
    redirect_to root_path and return false
  end
end