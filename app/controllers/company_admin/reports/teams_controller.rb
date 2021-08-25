class CompanyAdmin::Reports::TeamsController < CompanyAdmin::BaseController
  layout "reports_admin"

  def index
    @engagement_report = Report::Engagement::TeamsReport.new(@company, from: from, to: to)
    @datatable =  Report::Engagement::TeamsDatatable.new(view_context, @engagement_report)
    respond_with @datatable
  end

  private
  def from
    params[:from] || Interval.new(@company.reset_interval).start(shift: -1)
  end

  def to
    params[:to] || Interval.new(@company.reset_interval).end(shift: -1)
  end
end