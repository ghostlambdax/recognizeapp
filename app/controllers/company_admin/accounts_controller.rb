# frozen_string_literal: true

class CompanyAdmin::AccountsController < CompanyAdmin::BaseController
  include CachedUsersConcern
  include ServerSideExportConcern
  include LinksHelper

  before_action :set_company_from_network
  before_action :set_company_roles

  def show
    # @users = @company.users.includes(:user_roles, :company_roles)
    gon.uses_employee_id = @company.uses_employee_id?
    @users_datatable = datatable
    @users_datatable.log_debug!
    if request.xhr?
      respond_with @users_datatable
    else
      render action: "show"
    end
  end

  def edit
    @users = @company.users
    @bulk_user_updater = BulkUserUpdater.new(@company, current_user)
    @sort_key_prefix = Time.now.to_f.to_s
  end

  def update
    @bulk_user_updater = BulkUserUpdater.new(@company, current_user)
    @bulk_user_updater.update(bulk_user_updater_params)
    refresh_cached_users!
    respond_with @bulk_user_updater
  end

  def update_user_password
    user_params = params.require(:user).permit(:id, :password)
    @user = @company.users.find(user_params[:id])
    @user.password = user_params[:password]

    @user.skip_original_password_check = true
    @user.valid?
    @user.errors.add(:password, 'cannot be blank') if @user.password.blank?

    if @user.errors.count == 0
      @user.save
      render json: {}, status: 200
    else
      render json: {errors: @user.errors}, status: 422
    end
  end

  def user_password_reset_link
    user_params = params.require(:user).permit(:id)
    @user = @company.users.find(user_params[:id])

    render json: {
      password_reset_url: invite_or_password_reset_link(@user)
    }, status: 200
  end

  private

  def bulk_user_updater_params
    allowed_attrs = BulkUserUpdater::UPDATEABLE_ATTRS + %i[id create update]

    params
      .require(:bulk_user_updater).to_unsafe_h
      .select { |k, _v| k =~ /\A\d+\z/ }
      .transform_values do |attr_hash|
        attr_hash
          .slice(*allowed_attrs)
          .select { |_k, val| val.is_a?(String) }
    end
  end

  def datatable
    UsersDatatable.new(view_context, @company)
  end
end
