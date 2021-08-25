class CompanyAdmin::CustomizationsController < CompanyAdmin::BaseController
  before_action :set_company_from_network

  def show
    @customizations = find_customization_or_build
  end

  def update
    @customizations = find_customization_or_build

    @customizations.update(customization_params)

    respond_with @customizations
  rescue ImageAttachmentUploader::ImproperFileFormat => e

    error_key = :email_header_logo if customization_params.dig(:email_header_logo).present?
    error_key ||= :certificate_background if customization_params.dig(:certificate_background).present?
    error_key ||= :base
    @customizations.errors.add(error_key, e.message)
    respond_with(@customizations)
  end

  private
  def customization_params
    params.require(:company_customization).permit(CompanyCustomization.all_columns + [:stylesheet])
  end

  def find_customization_or_build(defaults = CompanyCustomization.defaults_without_virtual)
    @company.customizations || @company.build_customizations(defaults)
  end

end
