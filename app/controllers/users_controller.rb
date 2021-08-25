require 'will_paginate/array'
class UsersController < ApplicationController
  include UsersConcern
  include CachedUsersConcern
  include GonHelper
  include DateTimeHelper

  before_action :require_user_conditionally
  before_action :require_user_in_network, only: [:show, :received_recognitions, :sent_recognitions, :direct_reports], if: -> { scoped_user.company.private_user_profiles? }
  before_action :scoped_user, except: :index
  before_action :set_gon_attributes_for_recognition_delete_swal, only: [:show]
  before_action :set_gon_stream_comments_and_approvals_path, only: [:show]

  show_upgrade_banner only: [:index]

  filter_access_to :edit, :update, :hide_welcome, :has_read_new_feature, :upload_avatar, :update_slug, :revoke_oauth_token, :destroy, attribute_check: true

  skip_before_action :ensure_correct_company, only: [:show, :received_recognitions, :sent_recognitions, :direct_reports]

  layout "company_admin", only: :nominations

  def index
    # this was previously used by custom badge budgeting well
    # Can be used in the future for showing users by role in users index or anywhere else
    # if params[:role_ids].present?
    #   user_ids = scoped_company.get_user_ids_by_company_role_ids(params[:role_ids])
    #   @users = User.find(user_ids)
    # else
    #   @users = scoped_company.users.not_disabled
    # end

    @datatable = UserDirectoryDatatable.new(view_context, @company)
    respond_with(@datatable)
  end

  def coworkers
    @users = current_user.coworkers(params[:term])

    @users = @users[0..params[:limit].to_i-1] if params[:limit]

    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  # endpoint for getting counts of users by roles
  def counts
    @counts = UserCounts.new(@company, params)
    respond_to do |format|
      format.json { render json: @counts.user_counts }
    end
  end

  def show
    @point_history_datatable = @user.total_points > 0 ? UserPointActivitiesDatatable.new(view_context, @user) : nil
    @badge_counts = @user.badge_counts_via_setting
    @redemptions = scoped_user.redemptions.order("created_at desc")
    @achievements = scoped_user.received_recognitions.approved.select { |recognition| recognition.badge.is_achievement? }
    @completed_tasks = @user.completed_tasks.order("completed_tasks.created_at desc, completed_tasks.id asc")
    @total_task_points = PointActivity.completed_tasks.where(user: @user).sum(:amount)

    gon.redemption_additional_instructions_title = I18n.t('redemption.additional_instructions_for_user_title')
    gon.okay = I18n.t('dict.okay')
    render :action => "show"
  end

  def received_recognitions
    @received_recognitions = scoped_user.received_recognitions.approved
      .joins(:user_recipients, sender: :company)
      .includes(:user_recipients, sender: :company).select { |r| r.permitted_to?(:show) }
    @received_recognitions = @received_recognitions.paginate(:page => params[:page], :per_page => 10)
    render action: "received_recognitions", layout: false
  end

  def sent_recognitions
    @sent_recognitions = scoped_user.sent_recognitions.approved
      .joins(:user_recipients, sender: :company)
      .includes(:user_recipients, sender: :company).select { |r| r.permitted_to?(:show) }
    @sent_recognitions = @sent_recognitions.paginate(:page => params[:page], :per_page => 10)
    render action: "sent_recognitions", layout: false
  end

  def direct_reports
    @direct_reports = scoped_user.employees.not_disabled
    render action: "direct_reports", layout: false
  end

  # used by /users page to render nested rows
  def managed_users
    @manager = scoped_company.users.find(params[:id])
    @managed_users = @manager.employees.not_disabled.includes(:teams)
    @list_truncate_limit = 30
    @datatable = UserDirectoryDatatable.new(view_context, @company)
    render layout: false
  end

  def edit
    @user.email_setting || @user.build_email_setting
  end

  def update
    #HACK to add a year since we found out how sensitive people are for birth year.
    if params[:user]["birthday(2i)"] && params[:user]["birthday(3i)"]
      params[:user]["birthday(1i)"] = "1908"
    end

    @user.password_strength_check = true
    @user.enable_restricted_fields_check = true
    @user.check_original_password_when_changing_email = true
    if @user.update_profile(user_generic_params)

      #HACK - updating the password logs us out(ie resets persistence_token), so just force login for now
      #       until we can figure a better way
      if current_user.id == @user.id && current_user.persistence_token != @user.persistence_token
        UserSession.login_as!(@user)
      end
      locale = (current_user.id == @user.id && I18n.default_locale.to_s != @user.locale) ? @user.locale : nil
      url = edit_user_path(@user, locale: locale)
      flash[:notice] = t("user_edit.success_profile_updated")
      respond_with @user, location: url
    else
      respond_with @user
    end
  end

  def update_slug
    @user.slug = params[:user][:slug]
    @user.save
    respond_with @user, location: user_path(@user, anchor: "email-signature")
  end

  def upload_avatar
    @user.update_avatar(file: params[:user][:avatar])
    if @user.errors.blank?
      current_user(true)
      render json: { avatar_image_url: @user.avatar.thumb.url }
    else
      render json: { errors: @user.errors}, status: :unprocessable_entity
    end
  end

  def hide_welcome
    @user.update_attribute(:has_read_welcome, true)
  end

  def has_read_new_feature
    @user.has_read_feature!(params[:feature])
    head :ok
  end

  def invite
  end

  def send_invitations
    users_invited = []
    @user.delay(queue: 'priority').invite_from_yammer!(params[:user][:yammer_users])
    users_invited += @user.invite!(params[:user][:invitations])
    refresh_cached_users! if users_invited.any?

    flash[:notice] = I18n.t('dict.successfully_sent_invite')
    # saved_users, error_users = users_invited.partition{|u| u.errors.empty?}
    # if saved_users.length > 0
    #   flash[:notice] = "Successfully sent invitations for #{saved_users.length + params[:user][:yammer_users].length} users".html_safe
    # end

    # if error_users.length > 0
    #   flash[:notice] = (flash[:notice].present? ? flash[:notice]+"<br />".html_safe : "".html_safe)
    #   flash[:notice] += "The following users could not be invited: <ul>".html_safe
    #   error_users.each do |u|
    #     flash[:notice] += "<li>#{u.email} - #{u.errors.full_messages.to_sentence}</li>".html_safe
    #   end
    #   flash[:notice] += "</ul>".html_safe
    # end
    redirect_to invite_users_path
  end

  def invite_from_yammer
    results = @user.invite_from_yammer!(params[:users].values)
    render json: results
  end

  def get_suggested_yammer_users
    @yammer_users_to_invite = current_user.cached_relevant_coworkers
    emails_to_reject = User.where(email: @yammer_users_to_invite.map(&:email)).map(&:email)
    yammer_ids_to_reject = User.where(yammer_id: @yammer_users_to_invite.map(&:yammer_id)).map(&:yammer_id)
    @yammer_users_to_invite.reject! { |u| yammer_ids_to_reject.include?(u.yammer_id.to_s) || emails_to_reject.include?(u.email) }

    render action: "get_suggested_yammer_users", layout: false
  end

  def get_relevant_yammer_coworkers
    @people = current_user.relevant_coworkers.shuffle[0..5]
    render action: "get_relevant_yammer_coworkers", layout: false
  end

  def promote_to_admin
    @user.roles << Role.company_admin
    render action: "update_roles"
  end

  def demote_from_admin
    @user.user_roles.where(role_id: Role.company_admin.id).destroy_all
    render action: "update_roles"
  end

  def promote_to_executive
    @user.roles << Role.executive
    render action: "update_executive_role"
  end

  def demote_from_executive
    @user.user_roles.where(role_id: Role.executive.id).destroy_all
    render action: "update_executive_role"
  end

  def destroy
    @company ||= scoped_company
    @user = User.where(network: @company.domain).find_by_id!(params[:id])
    @user.destroy
    ManagerRoleSyncer.delay(queue: 'priority_caching').sync!(@user.company_id)
    @current_user_destroyed = (current_user == @user)
    logout_current_user if @current_user_destroyed
  end

  def activate
    @company ||= scoped_company
    @user = User.where(network: @company.domain).find_by!(id: params[:id])
    @user.activate!
    ManagerRoleSyncer.delay(queue: 'priority_caching').sync!(@user.company_id)
  end

  def revoke_oauth_token
    @application_id = params.fetch(:application_id)
    @tokens = @user.oauth_access_tokens.where(application_id: @application_id)
    @tokens.destroy_all
  end

  def goto
    if params[:type].present?
      send("goto_"+params[:type].to_s.downcase)
    else
      goto_user
    end
  end

  def unsubscribe
    if @user = User.read_unsubscribe_token(params[:token])
      if request.patch?
        @user.unsubscribe!
      end
    else
      render plain: "Invalid Link"
    end
  end

  def nominations
    @user = @company.users.find(params[:id])
    @nominations = Nomination.for_recipient(@user).where(badge_id: params[:badge_id])
    @nominations = @nominations.for_sender(current_user) unless current_user.company_admin?
  end

  def manager
    @user = User.find(params[:id])
    if params[:manager_id]
      @user.set_manager(params[:manager_id])
    else
      @user.clear_manager()
    end
    ManagerRoleSyncer.delay(queue: 'priority_caching').sync!(@user.company_id)
    render json: {manager_id: params[:manager_id]}
  end

  def device_token
    token = current_user.device_tokens.where(token: params[:device_token], platform: params[:device_platform]).first_or_create!
    render json: {token: token}
  end

  def update_favorite_teams
    if current_user.update_favorite_teams(params[:team_id].to_i, params[:add])
      head :ok
    else
      render json: { errors: current_user.errors }, status: :unprocessable_entity
    end
  end

  protected

  def goto_user
    network = params[:network] || @company.domain
    u = User.where(network: network, email: params[:email]).first
    if u
      redirect_to user_path(u, network: u.network)
    else
      redirect_to invite_users_path(network: current_user.network, email: params[:email])
    end
  end

  def goto_team
    # team = Team.where(name: params[:name]).first
    team = @company.teams.where(name: params[:name]).first
    redirect_to team_path(team)
  end

  def protect_access_to_current_user
    unless @user == current_user
      redirect_to user_path(@user)
      return false
    end
  end

  def id_is_int?(id)
    !!(id =~ /^[0-9]+$/)
  end

  def require_user_in_network
    unless current_user.domain_in_family?(scoped_user.network)
      raise Authorization::NotAuthorized, "You may not access this page"
    end
  end

  def require_user_conditionally
    actions_requiring_user_conditionally = [:show, :received_recognitions, :sent_recognitions, :direct_reports]
    actions_not_requiring_user = [:unsubscribe]
    if actions_requiring_user_conditionally.include?(action_name.to_sym) && !scoped_user.company.private_user_profiles?
      nil
    elsif actions_not_requiring_user.include?(action_name.to_sym)
      nil
    else
      require_user
    end
  end


  # whitelists the generic params that are passed when pressing the "save" button in edit page
  def user_generic_params
    params
      .require(:user)
      .permit([
                "first_name", "last_name", "display_name", "email", "original_password", "password",
                "job_title", "phone", "locale", "timezone",
                "start_date(1i)", "start_date(2i)", "start_date(3i)",
                "birthday(1i)", "birthday(2i)", "birthday(3i)",
                "receive_anniversary_recognitions_privately", "receive_birthday_recognitions_privately",
                "company_id",
                "email_setting_attributes" => allowable_email_setting_attributes
              ])
  end

  def allowable_email_setting_attributes
    %i[
      id
      activity_reminders
      new_comment
      new_recognition
      allow_admin_report_mailer
      allow_manager_report_mailer
      allow_recognition_sms_notifications
      receive_direct_report_peer_recognition_notifications
      receive_direct_report_anniversary_notifications
      receive_direct_report_birthday_notifications
      daily_updates
      weekly_updates
      monthly_updates
      global_unsubscribe
    ]
  end

  private

  def paper_trail_enabled_for_controller
    true
  end
end
