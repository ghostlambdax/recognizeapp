class CompanyAdmin::RewardsBudgetsController < CompanyAdmin::BaseController
  layout "rewards_admin"
  before_action :set_catalog

  def index
    @reward_calculator = Rewards::RewardPointCalculator.new(@company, @catalog)
    @point_form = PointsRequester.new
    @fee_percentage = 0
  end

  DEPOSIT_MESSAGE = "Your request to deposit money has been sent. Someone from our team will reach out to arrange the deposit shortly."
  def create
    @point_form = PointsRequester.new(point_requester_params.merge(company: @company, user: current_user, currency: @catalog.currency))

    if @point_form.valid?
      @point_form.send!
      flash[:notice] = DEPOSIT_MESSAGE
    end

    respond_with @point_form, location: company_admin_catalog_rewards_budgets_path(@catalog)
  end

  def point_requester_params
    params.require(:points_requester).permit(:amount)
  end

  private
  def set_catalog
    @catalog = @company.catalogs.find(params[:catalog_id])
    redirect_to company_admin_catalogs_path  unless @catalog
  end
end
