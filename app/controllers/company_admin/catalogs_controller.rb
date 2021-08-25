class CompanyAdmin::CatalogsController  < CompanyAdmin::BaseController
  layout :resolve_layout
  before_action :set_catalog, only: [:edit, :update]
  def index
    @catalogs = @company.catalogs
    @redemptions_for_chart = @company.redemptions.not_denied.includes(:reward)
    @datatable = CatalogsDatatable.new(view_context, @company)
    respond_with(@datatable)
  end

  def new
    @catalog = @company.catalogs.new
    @company_roles = @company.company_roles
  end

  def create
    @catalog = @company.catalogs.build(catalog_params)
    if @catalog.valid? && @catalog.save_with_roles
      flash[:notice] = "Catalog successfully created."
      respond_with(@catalog, location: company_admin_catalogs_path(catalog_id: @catalog.id))
    else
      @company_roles = @company.company_roles
      respond_with @catalog
    end
  end

  def edit
    @company_roles = @company.company_roles
  end

  def update
    @catalog.assign_attributes(catalog_params)
    if @catalog.valid? && @catalog.save_with_roles
      flash[:notice] = "Catalog successfully updated."
      respond_with(@catalog, location: company_admin_catalogs_path(catalog_id: @catalog.id))
    else
      @company_roles = @company.company_roles
      respond_with @catalog
    end
  end

  private

  def resolve_layout
    case action_name
    when "edit"
      "rewards_admin"
    else
      "catalogs_admin"
    end
  end

  def catalog_params
    params.require(:catalog).permit(:currency, :points_to_currency_ratio, :is_enabled, :company_roles => [])
  end

  def set_catalog
    @catalog = @company.catalogs.find(params[:id])
    redirect_to company_admin_catalogs_path  unless @catalog
  end
end
