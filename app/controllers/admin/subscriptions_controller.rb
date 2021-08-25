class Admin::SubscriptionsController < Admin::BaseController
  before_action :set_company, except: [:index]

  def index
    @subscriptions = Subscription.all
    @mrr = Subscription.mrr_total
    @yrr = Subscription.yrr_total
    @active_subscriptions = Subscription.active
    @canceled_subscriptions = Subscription.canceled
  end

  def edit
    @subscription = Subscription.find_by_id(params[:id])
    @user = @subscription.user
    @company = @subscription.company
  end

  def new
    if !company_has_subscription?
      @subscription = Subscription::Creator.initialize_subscription(@company, current_user)
    else
      flash[:error] = "A subscription already exists for that user's company"
      redirect_to "/admin/subscriptions"
    end
  end

  def create
    @subscription = Subscription::Creator.create(@company, current_user, subscription_params)
    flash[:notice] = "Subscription created" unless @subscription.errors.present?
    respond_with @subscription, location: admin_subscriptions_path
  end

  def update
    @subscription = Subscription::Updater.update(@company, current_user, subscription_params)
    flash[:notice] = "Subscription updated" unless @subscription.errors.present?
    respond_with @subscription, location: admin_subscriptions_path
  end

  def cancel
    @company.subscription.cancel!
    flash[:notice] = "Subscription for #{@company.domain} has been cancelled"
    render js: "window.location = '#{admin_subscriptions_path}';"
  end

protected

  def company_has_subscription?
    @company.subscription.present?
  end

  def subscription_params
    params
      .require(:subscription)
      .permit([:contract_title, :contract_body, :billing_label, :billing_start_date,
               :charge_interval, :amount, :department, :notes, :payment_method, :status,
               line_items_attributes: %i[amount description _destroy]])
      .merge({ skip_signature_validation: true, skip_user_count_validation: true })
  end

  def set_company
    @company = Company.where(domain: params[:company_id]).first
    raise ActionController::RoutingError.new('Not Found') unless @company.present?
  end

end