class Admin::CompaniesController < Admin::BaseController
  before_action :set_company
  def show
    @users = @company.users.includes(:authentications, :user_roles).not_disabled
    @subscription = @company.subscription || Subscription.new(user_count: @company.users.size)
    @money_depositer = Rewards::MoneyDepositer.new(company: @company)
    @invoice_documents = InvoiceDocument.where(company_id: @company.id).order("created_at desc").limit(5)
  end

  def create
    new_company = @company.make_child_company!(params[:company][:domain])
    respond_with new_company, location: admin_company_path(@company)
  end

  def deposit_money
    @money_depositer = Rewards::MoneyDepositer.new(money_depositer_params)
    @money_depositer.form_id = params[:form_id]

    if @money_depositer.deposit!
      flash[:notice] = "Money deposited!"
    end

    respond_with @money_depositer, location: admin_company_path(@company)
  end

  def enable_custom_badges
    @company.delay(queue: 'priority_caching').enable_custom_badges!
  end

  def enable_admin_dashboard
    @company.enable_admin_dashboard!
  end

  def compile_theme
    @company.compile_theme!
  rescue => e
    render json: {errors: {base: [e.message]}}, status: 422
  end

  def toggle_setting
    is_company_setting_attribute = params[:company_setting].present?
    record, @setting = begin
      if is_company_setting_attribute
        [@company.settings, params[:company_setting]]
      else
        [@company, params[:setting]]
      end
    end
    @setting = @setting.to_sym
    record.toggle!(@setting)
  end

  def upload_invoice
    @invoice_document = InvoiceDocument.new(invoice_document_params)
    if @invoice_document.save
      head :no_content
    else
      respond_with @invoice_document
    end
  end

  def update_invoice
    @invoice_document = InvoiceDocument.where(company_id: @company.id).find(params[:invoice_id])
    @invoice_document.description = params[:description] if params[:description].present?
    @invoice_document.due_date = params[:due_date] if params.key?(:due_date)
    @invoice_document.date_paid = params[:date_paid] if params.key?(:date_paid)
    @invoice_document.save!
    head :no_content
  rescue => e
    msg = ActionController::Base.helpers.escape_javascript(e.message)
    render js: "Swal.fire('#{msg}')", status: 500
  end

  def delete_invoice
    @invoice_document = InvoiceDocument.where(company_id: @company.id).find(params[:invoice_id])
    if @invoice_document.destroy
      head :no_content
    else
      respond_with @invoice_document
    end
  end

  def enable_achievements
    @company.enable_achievements!
  end

  def users
    respond_with(UsersDatatable.new(view_context, @company))
  end

  def add_users
    @company.add_users!(params[:company][:users], optimize_cache_refreshing: true)
    flash[:notice] = "Users successfully added" if @company.persisted?
    # respond_with @company, location: admin_company_path(@company)
    respond_with @company, location: request.referer
  end

  def add_directors
    @user = @company.add_director!(params[:user][:email])
  rescue Exception => e
    @error = e.message
  end

  def add_invoice_document
    @invoice = InvoiceDocument.new
  end

  def update_price_package
    if @company.update_price_package(params[:company][:price_package])
      head :no_content
    else
      head :unprocessable_entity
    end
  end

  def remove_directors
    @user = @company.remove_director!(params[:user_id])
  rescue Exception => e
    @error = e.message
  end

  def set_sync_frequency
    @company.settings.update(sync_frequency: params[:sync_frequency])
  end

protected
  def set_company
    @company = Company.where(domain: params[:id]).first
    raise ActionController::RoutingError.new('Not Found') unless @company.present?
  end

  def money_depositer_params
    # params[:rewards_money_depositer].merge(company: @company)
    params.require(:rewards_money_depositer).permit(:amount, :funding_source_id, :comment).merge(company: @company)
  end

  def invoice_document_params
    params.fetch(:invoice_document).permit(:file, :description, :due_date).tap do |p|
      p[:uploader_id] = current_user.id
      p[:company_id] = @company.id
    end
  end
end
