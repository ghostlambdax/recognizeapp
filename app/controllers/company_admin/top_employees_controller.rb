class CompanyAdmin::TopEmployeesController < CompanyAdmin::BaseController
  include ReportsConcern

  layout "reports_admin"

  # The actual report table is lazy-loaded separately via companies#top_employees_report endpoint
  def index
    setup_leaderboard(skip_report: true)
  end
end
