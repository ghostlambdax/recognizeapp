class ManagerAdmin::BaseController < ApplicationController
  include CompanyAdminConcern

  skip_before_action :set_company_roles
  skip_before_action :restrict_to_company_admin

  layout "manager_admin"

end