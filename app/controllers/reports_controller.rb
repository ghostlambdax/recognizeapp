class ReportsController < ApplicationController
  include ReportsConcern
  show_upgrade_banner only: [:index]

  def index
    start_date
    end_date
    @badge = get_badge_by_params
  end

  def users
    @badge = get_badge_by_params
    @report = Report::Company.new(current_user.company, start_date, end_date, badge_id: params[:badge_id], points_only: true)
    render action: "users", layout: false
  end

  def teams
    @badge = get_badge_by_params
    @report = Report::Company.new(current_user.company, start_date, end_date, badge_id: params[:badge_id])
    render action: "teams", layout: false
  end

  def top_users
    @attribute = params[:sort].try(:to_sym)
    @badge = Badge.cached(params[:badge_id]) if params[:badge_id]
    @report = Report::Company.new(@company, start_date, end_date, badge_id: @badge.try(:id), "#{@attribute}_only".to_sym => true)
    @top_users = @report.user_leaderboard(:points)
  end

  def top_yammer_users
    @user_stats = ExternalActivity.user_like_stats(
        company: current_user.company,
        start_date: start_date,
        end_date: end_date
    )
    render action: "top_yammer_users", layout: false
  end

  def top_yammer_groups
    @group_stats = ExternalActivity.group_like_stats(
        company: current_user.company,
        groups: yammer_groups,
        start_date: start_date,
        end_date: end_date
    )
    render action: "top_yammer_groups", layout: false
  end

  private

  def get_badge_by_params
    Badge.cached(params[:badge_id]) if params[:badge_id].present?
  end

  # TODO: refactor this to use service class
  def yammer_groups
    return { "1" => "rails" } if Rails.env.test?
    Hash[current_user.yammer_client.get_all_groups.map { |g| [ g.id.to_s, g.name ] }]
  end
end
