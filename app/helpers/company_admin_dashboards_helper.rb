module CompanyAdminDashboardsHelper

  def reports_nav_dashboard_link
    content_tag(:li, class: ('active' if current_page?(company_admin_dashboard_path))) do
      link_to t("layouts.company_admin_sidebar.overview"), company_admin_dashboard_path(network: current_user.company.domain)
    end
  end

  def reports_top_employees_index_link
    content_tag(:li, class: ('active' if active_subnav?("/company/top_employees"))) do
      link_to t("layouts.company_admin_sidebar.top_employees"), company_admin_top_employees_path
    end
  end

  def reports_engagement_link
    # TODO: this is not the greatest, but hopefully, its ok, enough. 
    content_tag(:li, class: ('active' if active_subnav?("/company/reports"))) do
      link_to "Engagement", company_admin_reports_roles_path
    end
  end

  def reports_roles_link
    content_tag(:li, class: ('active' if current_page?(company_admin_reports_roles_path))) do
      link_to "By Role", company_admin_reports_roles_path
    end
  end

  def reports_teams_link
    content_tag(:li, class: ('active'if current_page?(company_admin_reports_teams_path))) do
      link_to "By Team", company_admin_reports_teams_path
    end
  end

  def reports_departments_link
    content_tag(:li, class: ('active'if current_page?(company_admin_reports_departments_path))) do
      link_to "By Department", company_admin_reports_departments_path
    end
  end

  def reports_countries_link
    content_tag(:li, class: ('active'if current_page?(company_admin_reports_countries_path))) do
      link_to "By Country", company_admin_reports_countries_path
    end
  end
end
