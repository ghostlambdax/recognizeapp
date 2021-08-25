# frozen_string_literal: true

class CompanyAdmin::Anniversaries::BaseController < CompanyAdmin::BaseController
  layout "company_admin_tertiary"

  def tertiary_title
    "Anniversaries"
  end
  helper_method :tertiary_title

  def manager_admin_controller?
    controller_path.match(/^manager_admin/).present?
  end
  helper_method :manager_admin_controller?
end
