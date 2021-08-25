class CompaniesController < ApplicationController
  include CompanyAdminConcern
  include ReportsConcern
  filter_access_to  :show, :update, :update_privacy,
                    :add_users, :update_point_values, :update_recognition_limits,
                    :update_settings, :yammer_groups, attribute_check: true
  show_upgrade_banner only: [:show]

  respond_to :csv, :xls # , :pdf

  attr_accessor :check_list
  before_action :set_catalog, only: [:show]

  def show
    point_calculator = Rewards::RewardPointCalculator.new(@company, @catalog)
    gon.show_budgets = true # stub if we want to hide for certain companies
    gon.currency = @catalog&.currency_prefix
    gon.points_to_currency_ratio = point_calculator.points_to_currency_ratio
    gon.reset_interval_id = @company.reset_interval
    gon.intervals = Interval.reset_intervals
    gon.interval_conversion_map = Interval.conversion_map
    gon.user_count = @company.users.size
    gon.user_count_by_role = CompanyRole.user_count_by_role(@company)
    gon.counts_users_url = counts_users_url

    @res_calculator = ResCalculator.new(@company)
    @user = current_user
    @company = Company.includes(users: :user_roles).find_by(domain: scoped_network)
    @users = User.where(company_id: @company.id).includes(:user_roles)
    @roles = collect_anniversary_roles
    @teams = @company.teams

    @recognitions = Recognition.for_company(@company).user_sent
    @badge = @company.badges.build(sending_interval_id: @company.reset_interval)

    @attribute = params[:sort].try(:to_sym) || :received_recognitions
    @time_period = Time.now.prev_month.all_month
    @report = Report::Company.new(@company, @time_period.first, @time_period.last)
    @top_badges = @company.top_badges
    @non_deletable_badge_ids = Recognition.select("distinct badge_id").where(sender_company_id: 1).pluck(:badge_id)
    @company_roles = @company.company_roles
    @show_active_badges = params[:status] != 'disabled'
  end

  def update
    company_params = params[:company]
    if company_params
      @company.update_column(:name, company_params[:name]) if company_params[:name].present?
    end
    head :ok
  end

  def sync_yammer_stats
    ExternalActivities::SyncService.delay.sync_yammer_activities(initiator: current_user)
  end

  def update_privacy
    @company.update_global_privacy(params[:privacy])
    head :ok
  end

  def update_point_values
    @company.update_point_values(point_value_params)
    @company.settings.update(point_value_redeemable_params[:settings])

    flash[:notice] = "Successfully updated point values" if @company.errors.count == 0
    head :ok
  end

  def update_kiosk_mode_key
    key = params[:company][:kiosk_mode_key]
    key.gsub!(/\s+/, "")
    @company.update_kiosk_mode_key(key)
    kiosk_url_partial = render_to_string(partial: "companies/kiosk_url")
    respond_with @company, onsuccess: {method: "fireEvent", params: {name: "kioskUrlUpdated", kiosk_url_partial:  kiosk_url_partial}}
  end

  def update_recognition_limits
    @company.update_recognition_limits(recognition_limit_params)
    # flash[:notice] = "Successfully updated badge sending limits" if @company.errors.count == 0
    head :ok
  end

  def bulk_update; end

  def add_users
    @company.add_users!(params[:company][:users], skip_cache_refreshing: true)
    flash[:notice] = "Users successfully added" if @company.persisted?
    # respond_with @company, location: admin_company_path(@company)
    respond_with @company, location: request.referer
  end

  def update_settings
    @company.update_settings!(setting_params.to_h)
    head :ok
  end

  def setting_params
    settings = params[:settings] || params[:company]

    settings.permit(
      allowable_settings_on_company,
      settings: allowable_settings_on_company_settings,
      saml_configuration: allowable_settings_on_saml_configuration
    )
  end

  def top_employees_report
    setup_leaderboard
  end

  def resend_invitation_email
    opts, medium = if params[:email]
      [{ email: params[:email] }, :email]
    else
      [{ phone: params[:phone] }, :phone]
    end
    @user = @company.users.where(opts).first
    @user.reset_perishable_token! if @user.perishable_token.blank?
    verification_url = @user.company.saml_enabled_and_forced? ? sso_saml_index_url(network: @user.network) : verify_signup_url(@user.perishable_token)
    current_user.resend_invite!(@user, medium, verification_url)
  end

  protected
  def allowable_settings_on_company
    Company::SETTINGS
  end

  def allowable_settings_on_company_settings
    %i[
      anniversary_recognition_custom_sender_name
      fb_workplace_community_id
      fb_workplace_token
      fb_workplace_post_to_group_id
      fb_workplace_enable_post_to_group
      profile_badge_ids
      tasks_enabled
      yammer_sync_groups
      microsoft_graph_sync_groups
      sync_phone_data
      sync_service_anniversary_data
      sync_managers
      sync_display_name
      default_locale
      sync_job_title
      default_birthday_recognition_privacy
      default_anniversary_recognition_privacy
      allow_manager_of_manager_notifications
      allow_phone_authentication
      default_receive_direct_report_peer_recognition_notifications
      default_receive_direct_report_anniversary_notifications
      default_receive_direct_report_birthday_notifications
      authentication_field
      timezone
      sync_email_with_upn
      tasks_redeemable
      sync_department
      sync_country
      force_sso
      require_recognition_tags
      allow_manager_to_resolve_recognition_she_sent
      autolink_fb_workplace_accounts
      allow_webhooks
    ] << {
      sync_filters: { microsoft_graph: :accountEnabled },
      recognition_editor_settings: %i[allow_links allow_inserting_images allow_uploading_images allow_gif_selection]
    }
  end

  def allowable_settings_on_saml_configuration
    %i[
      is_enabled
      metadata_url
      entity_id
      sso_target_url
      slo_target_url
      name_identifier_format
      certificate
    ]
  end

  #collect all roles should return actual roles instead of the names of the roles.
  #later on you can extract the names of the roles.  this should also be moved to company.rb
  #also let's rename it collect all anniversary rolesaa.
  def collect_anniversary_roles
    role_names = ["Company Admin", "Executive"]
    roles = []
    role_names.each do |role_name|
      roles << Role.find_by_long_name(role_name)
    end
    return roles
  end

  def point_value_params
    params.require(:company).permit(:sent_recognition_value, :received_approval_value, :sent_approval_value)
  end

  def point_value_redeemable_params
    params.require(:company).permit(settings: [:sent_recognition_redeemable, :received_approval_redeemable, :sent_approval_redeemable])
  end

  def recognition_limit_params
    params.require(:company)
      .permit(:default_recognition_limit_interval_id, :default_recognition_limit_frequency,
              :default_recognition_limit_scope_id, :recognition_limit_interval_id, :recognition_limit_frequency,
              :recognition_limit_scope_id)
  end

  def set_catalog
    company = Company.find_by(domain: scoped_network)
    @catalog = company.catalogs.find_by_id(params[:catalog_id]) || company.principal_catalog
  end

  def paper_trail_enabled_for_controller
    true
  end
end
