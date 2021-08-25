# frozen_string_literal: true

class CompanyAdmin::Anniversaries::SettingsController < CompanyAdmin::Anniversaries::BaseController
  include SharedParamsConcern
  before_action :set_catalog, only: [:index]

  def index
    @anniversary_badges = assemble_anniversary_badges
    gon.points_to_currency_ratio = @catalog&.points_to_currency_ratio
    gon.currency = @catalog&.currency_prefix
  end

  def update_badge
    @badge = AnniversaryBadgeManager.update_or_create(@company, badge_params)
    respond_with @badge
  rescue StandardError, ImageAttachmentUploader::ImproperFileFormat => e
    render json: { errors: {base: [e.message]} }, status: :unprocessable_entity
  end

  private

  def assemble_anniversary_badges
    AnniversaryBadgeManager.company_anniversary_badges(@company)
  end

  def set_catalog
    @catalog = @company.catalogs.find_by_id(params[:catalog_id]) || @company.principal_catalog
  end

end
