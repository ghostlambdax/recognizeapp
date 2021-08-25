module CompanyAdminConcern
  extend ActiveSupport::Concern

  included do
    before_action :require_user
    before_action :set_company_from_network, except: :show
    before_action :set_company_roles, except: :show
    before_action :restrict_to_company_admin, if: ->{ @company.allow_admin_dashboard? }
  end

  private

  def restrict_to_company_admin
    unless current_user.admin? || current_user.company_admin?
      flash[:notice] = "You must be the company administrator to access this page"
      redirect_to login_path
    end
  end

  def scoped_network
    params[:dept].presence || params[:network].presence
  end

  # this psuedo-hack lets declarative authorization play nicely and redirect
  # to login when not logged in
  def set_company_from_network
    @company = Company.where(domain: scoped_network).first
  end

  def set_company_roles
    # I added in some defensiveness if @company is blank
    # Found this to occur on CompanyAdmin::CustomizationsController
    # when I implemented saving stylesheet via super admin but posting to that controller
    # I think what's happening is that the CompanyAdmin::CustomizationsController
    # adds before_action :set_company_from_network which changes the callback order
    # defined here, so set_company_roles ends up getting called before set_company
    # in that controller. 
    @company_roles = @company&.company_roles || set_company_from_network.company_roles
  end

end
