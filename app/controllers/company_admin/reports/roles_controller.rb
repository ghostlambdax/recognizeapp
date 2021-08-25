class CompanyAdmin::Reports::RolesController < CompanyAdmin::BaseController
  layout "reports_admin"


  def index
    @engagement_report = Report::Engagement::RolesReport.new(@company, from: from, to: to)
    @datatable = Report::Engagement::RolesDatatable.new(view_context, @engagement_report)
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
