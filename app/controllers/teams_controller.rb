require "will_paginate/array"
class TeamsController < ApplicationController
  before_action :build_team, only: [:create] # need to build so declarative authorization can check company for permissions
  before_action :set_team, only: [:show, :edit, :update, :destroy, :members]
  before_action :set_gon_stream_comments_and_approvals_path, only: [:show]

  filter_access_to :new, :create, :edit, :update, :show, :destroy, attribute_check: true
  show_upgrade_banner only: [:index]
  layout "company_admin", only: :nominations
  layout false, only: :members

  def index
    @user = current_user
    @users_teams = current_user.teams.includes(users: :avatar).order("teams.name asc")

    @other_teams = @company.teams.includes(users: :avatar)
                     .where.not(teams: { id: @users_teams.map(&:id) })
                     .order("teams.name asc")
                     .paginate(page: params[:page], per_page: 10)

    # @users_teams is not paginated, so only render @other_teams for pagination requests
    @show_other_teams_only = params[:page].present? && params[:page] != '1'

    gon.feedback_messages = {
      duplicate_team: I18n.t('teams.team_already_exists'),
      team_created: I18n.t('teams.team_created')
    }

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @teams }
    end
  end

  def paginated_index(page = 1)
    @combined_teams = nil
    joined_teams = current_user.joined_teams
    starred_teams = nil

    if joined_teams.count < 10
      starred_teams = current_user.starred_teams
      starred_joinied_count = starred_teams.count + joined_teams.count

      if starred_joinied_count < 10
        number_to_get = 10 - starred_joinied_count

        teams = teams_minus_joined_starred(number_to_get)

        @combined_teams << teams
        @combined_teams << starred_teams
        @combined_teams << joined_teams

      else

        @combined_teams << starred_teams
        @combined_teams << joined_teams

      end

    else

      @combined_teams << joined_teams

    end


    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @combined_teams }
    end
  end

  def create
    @team = current_user.create_team(team_params)
    respond_with @team
  end

  def show
    query = @team.received_recognitions
      .includes(:badge, :recognition_recipients, {sender: [:company, :user_roles]})
    query = query.recipients_active.sender_active if @company.settings.hide_disabled_users_from_recognitions?
    per_page = 10
    @recognitions = Recognition
      .select_permitted_recognitions_with_page_limit(query, page: params[:page], per_page: per_page)
      .paginate(page: params[:page], per_page: per_page)

    # render only the relevant view for pagination requests
    if params[:page] && request.xhr?
      render partial: "recognitions", object: @recognitions
    end

    @team_managers = @team.managers.active.includes(:avatar)
  end

  def edit
  end

  def update
    @team.update(team_params)
  end

  def destroy
    @team.destroy

    respond_to do |format|
      format.html { redirect_to teams_url }
      format.js { render js: "$('##{dom_id(@team)}').remove()" }
    end
  end

  def add_members
    render action: "add_members", layout: false
  end

  # This action has been discontinued.
  def nominations
    # @team = Team.find_from_recognize_hashid(params[:id])
    # @nominations = Nomination.for_recipient(@team).where(badge_id: params[:badge_id])
    # @nominations = @nominations.for_sender(current_user) unless current_user.company_admin?
    render file: Rails.root.join('public', '404.html'), :status => 404
    # render file: "public/404", :status => 404
  end

  # used by #show page, loaded as pagelet
  def members
    @team_members = @team.users.not_disabled.includes(:avatar)
  end

  protected

  def set_team
    @team = @company.teams.find_from_recognize_hashid(params[:id]) if current_user
  rescue ActiveRecord::RecordNotFound => e
    flash[:error] = "Sorry, that team does not exist."
    redirect_to root_path and return false
  end

  def build_team
    @team = @company.teams.build if current_user
  end

  def team_params
    params.require(:team).permit(:name)
  end
end
