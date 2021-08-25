module ReportsConcern
  extend ActiveSupport::Concern
  included do
    before_action :start_date
    before_action :end_date
  end

  private

  def date_range
    @date_range ||= DateRange.new(params[:start_date] || current_user.interval_start_date, params[:end_date] || current_user.interval_end_date)
  end

  def start_date
    @start_date ||= date_range.start_time
  end

  def end_date
    @end_date ||= date_range.end_time
  end

  def setup_leaderboard(skip_report: false)
    @attribute = params[:sort].try(:to_sym) || :received_recognitions
    @badge = Badge.cached(params[:badge_id]) if params[:badge_id]
    @team = @company.teams.find(params[:team_id]) if params[:team_id]
    @company_role = @company.company_roles.find_by_id(params[:company_role_id]) if params[:company_role_id]

    unless skip_report
      @report = Report::Company.new(
        @company,
        start_date,
        end_date,
        badge_id: @badge.try(:id),
        team_id: @team.try(:id),
        company_role_id: @company_role.try(:id),
        "#{@attribute}_only".to_sym => true,
        attribute_filter_key: params[:attribute_filter_key].try(:to_sym),
        attribute_filter_value: params[:attribute_filter_value].present? && params[:attribute_filter_value].to_i
      )
      @team_members = @report.user_leaderboard(@attribute)
    end
  end
end
