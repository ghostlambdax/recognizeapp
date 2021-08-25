class CompanyAdmin::DashboardsController < CompanyAdmin::BaseController
  before_action :set_company_from_network
  layout "reports_admin"

  def show
    @res_calculator = ResCalculator.new(@company)
    @users = User.not_disabled.where(company_id: @company.id).includes(:user_roles)
    @user = current_user
    @recognitions = Recognition.approved.for_company(@company).user_sent
    @top_badges = @company.top_badges
    @users_by_status = @company.users_by_status
    @saml_configuration = @company.saml_configuration || @company.build_saml_configuration
    @support_email = SupportEmail.new
    @support_email.type = params[:type]
  end


end
