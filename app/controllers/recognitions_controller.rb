class RecognitionsController < ApplicationController
  include CachedUsersConcern
  include TeamsHelper
  include TrumbowygHelper
  include GonHelper
  include HttpCacheConcern

  before_action :require_network, except: [:show, :share, :certificate]
  before_action :ensure_sso, only: [:show]
  before_action :require_user_conditionally
  before_action :redirect_personal_accounts, only: [:index, :grid], unless: :has_secret_password?
  before_action :verify_user, only: :show, if: Proc.new{|c| params[:invite].present? }
  before_action :verify_crawler, only: :show
  before_action :setup_recognition, only: [:new, :new_chromeless, :create, :upload_image]
  before_action :setup_tags, only: [:new, :new_chromeless, :new_panel]
  before_action :send_to_correct_start_form, only: [:new, :new_chromeless]
  before_action :set_gon_team_counts, only: [:new, :new_chromeless]
  before_action :set_send_recognition_form, only: [:new, :new_chromeless, :new_panel]
  before_action :redirect_old_grid_paths, only: [:index]
  before_action :set_gon_attrs_for_trumbowyg, only: [:new, :new_chromeless, :new_panel, :edit]
  before_action :set_gon_attributes_for_recognition_delete_swal, only: [:index, :grid, :show]
  before_action :set_gon_stream_comments_and_approvals_path, only: [:index, :grid]

  filter_access_to :new, :create, :edit, :update, :show, :certificate, :toggle_privacy, :destroy, :upload_image,
                   attribute_check: true

  skip_before_action :set_send_recognition_form, only: [:recognize_instantly]


  # GET /recognitions
  # GET /recognitions.json
  def index
    @per_page_count = 10
    set_recognitions

    if current_user
      @teams = teams_without_favorites.paginate(page: (params[:teams_page]), per_page: 10)
      @selected_team = Team.find_from_recognize_hashid(params[:team_id]) if params[:team_id]
      @my_teams = favorite_joined_teams
      @filter_by = params[:filter_by] if params[:filter_by].present?
      @anniversary_recognitions_present = @company.recognitions.includes(:badge).where(badges: { is_anniversary: true }).exists?
    end

    if request.xhr?
      # this header is needed only for few cases where this page restore is somehow not handled by turbolinks
      ensure_no_cache!
      render layout: false
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @recognitions }
    end
  end

  def grid
    last_recognition_id = Recognition.where(sender_company_id: @company.id).first&.id
    last_comment_id = Comment.where(company_id: @company.id).last&.id
    last_approval_id = RecognitionApproval.where(company_id: @company.id).last&.id
    cache_key = "#{last_recognition_id}-#{last_comment_id}-#{last_approval_id}-#{params[:team_id]}-#{params[:page]}"
    if stale?(etag: cache_key)
      @per_page_count = 15 # this needs to be set before set_recognitions
      set_recognitions
      @team = Team.find(params[:team_id]) if params[:team_id]
      @is_first_page = !params[:page] || params[:page] == '1'
      filter_slug_to_label_map = {
        'recognition' => I18n.t('dict.peer_to_peer'),
        'anniversary' => I18n.t('dict.anniversaries')
      }
      @filter_by = params[:filter_by].map { |badge| filter_slug_to_label_map[badge] } if params[:filter_by].present?
      render layout: !request.xhr?
    end
  end

  def teams
    @selected_team = Team.find_from_recognize_hashid(params[:team_id]) if params[:team_id]
    @teams = teams_without_favorites.paginate(page: (params[:teams_page].to_i), per_page: 10)
    render layout: !request.xhr?
  end

  # GET /recognitions/1
  # GET /recognitions/1.json
  def show
    @recognition ||= Recognition.find_from_param(params[:id])
    raise ActiveRecord::RecordNotFound unless @recognition.kind_of?(Recognition)

    respond_to do |format|
      format.html do
        gon.recognition = {
          award_recipient_title: t('recognition_show.choose_award_recipient'),
          view: t('dict.view'),
          select_user: t('recognition_show.select_user'),
          recipients_data: recipients_data_for_show_page(@recognition)
        } if @recognition.recipients.size > 1
        @participants_for_nametag = @recognition.participants
        show_layout = !params.has_key?(:skip_layout)
        render "show", layout: show_layout
      end

      format.json { render json: @recognition }
    end
  end

  def certificate
    @recognition ||= Recognition.find_from_param(params[:id])
    company = @recognition.authoritative_company
    recipient = params[:recipient_type]&.downcase
    if recipient == 'user'
      @recipient = company.users.find_from_recognize_hashid(params[:recipient])
    elsif recipient == 'team'
      @recipient = company.teams.find_from_recognize_hashid(params[:recipient])
    end

    if company.customizations.present? && company.customizations.certificate_background.present?
      @certificate_url = company.customizations.certificate_background.url(:print)
    else
      @certificate_url = "pages/recognitions/show/certificate.png"
    end

    raise ActiveRecord::RecordNotFound unless @recognition.kind_of?(Recognition)
  end

  # GET /recognitions/new
  # GET /recognitions/new.json
  def new
    @recognition = current_user.sent_recognitions.new(recognition_params)

    # FIXME: change to support multiple recipients via email addresses
    #        also, need to change recognitions/_new_form.html.erb
    @recognition.send(:convert_recipient_emails_to_user)

    # 5/23/2019
    # I think this should eventually be deleted,
    # but leaving here in case any issues arise with prepopulating recipients or
    # rendering new form with errors
    # @send_recipients = @recognition.user_recipients if @recognition.user_recipients.present?
    # @send_recipients ||= @company.users.find(params[:recipient_id]) rescue nil

    @user_team_map = current_user.company.user_team_map
    @pageName = "recognition"
    @jsClass = "Recognition"
    #@recipient =  User.where(slug: params[:recipient], network: params[:recipient_network]).first if params[:recipient] and params[:recipient_network]

    respond_to do |format|
      format.html {
        if params[:layout] === "false"
          render partial: "recognitions/new_form"
        else
          render action: "new"
        end
      }
      format.json { render json: @recognition }
    end
  end

  # Used in Yammer.
  def new_chromeless
    @recognition = current_user.sent_recognitions.new(recognition_params)
    @pageName = "recognition"
    @jsClass = "Recognition"
    @user_team_map = current_user.company.user_team_map

    render action: "new", layout: "application_chromeless"
  end

  # Used in Outlook.
  def new_panel
    @recognition = current_user.recognitions.new(recognition_params)
    @pageName = "recognition"
    @jsClass = "Recognition"
    @user_team_map = current_user.company.user_team_map

    render action: "new_panel", layout: "application_panel"
  end

  def upload_image
    tempfile = params['file'].try(:tempfile)
    return render(failure_hash_for_image_upload) if !tempfile || !File.file?(tempfile)

    uploader = RecognitionImageUploader.new(@company)
    uploader.store!(tempfile)

    render success_hash_for_image_upload(uploader)

  # common case here is upload of non-permitted file type
  rescue CarrierWave::UploadError, ImageAttachmentUploader::ImproperFileFormat => exception
    render failure_hash_for_image_upload(message: exception.message)
  end

  # POST /recognitions
  # POST /recognitions.json
  def create
    @recognition = current_user.recognitions.new(recognition_params)
    @recognition.viewer = params[:viewer]
    @recognition.viewer_description = params[:viewer_description]

    #make sure we can't override the sender id or company
    @recognition.sender = current_user
    @recognition.save

    if @recognition.persisted?
      refresh_cached_users! if @recognition.has_invited_users?

      props = {role:  (current_user.company_admin? ? "company_admin" : "employee"), sent: true, badge: @recognition.badge.name}
      flash_add_prop_to_page_event(props)

    else
      @recognition.consolidate_errors
    end

    recognition_path_opts = @recognition.approved? ? {recognition_created: true} : {}
    url = @recognition.persisted? ? recognition_path(@recognition, recognition_path_opts) : nil
    respond_with @recognition, flash: {notice: "Your recognition has been sent"}, location: url
  end

  def edit
    @recognition = Recognition.find_from_param(params[:id])

    if @recognition.tags.present? || current_user.company.recognition_tags_enabled?
      # So it will just load tags that are selected
      @selected_tags = @recognition.tags
    end

    gon.recognition_format = @recognition.input_format
    respond_with @recognition
  end

  def update
    @recognition = Recognition.find_from_param(params[:id])
    if @recognition.update(recognition_params)
      respond_to do |format|
        format.html { redirect_to recognition_path(@recognition) }
        format.js { render js: "Turbolinks.visit('#{recognition_path(@recognition)}')" }
      end
    else
      respond_with(@recognition)
    end
  end

  # DELETE /recognitions/1
  # DELETE /recognitions/1.json
  def destroy
    @recognition = Recognition.find_from_param(params[:id])
    @recognition.destroy
    #
    respond_to do |format|
      format.html { redirect_to recognitions_url}
      format.js {render action: "destroy"}
    end
  end

  def toggle_privacy
    @recognition = Recognition.find_from_param(params[:id])

    if @recognition.is_public_to_world?
      @recognition.set_privacy_to_company!(false)
    else
      @recognition.set_privacy_to_company!(true)
    end

    respond_with @recognition
  end

  #You can permalink to share a recognition
  def share
    @recognition = Recognition.find_from_param(params[:id])
    raise ActiveRecord::RecordNotFound unless @recognition.present?

    @recognition.make_public! if permitted_to? :toggle_privacy
    redirect_to SocialShare.new(params[:provider],
      render_to_string(partial: "recognitions/title", locals: {recognition: @recognition}),
      recognition_url(@recognition), @recognition.message).url
  end

  def recognize_instantly
    @recognition = Recognition.instant(current_user, recognition_params)

    if @recognition.save
      @recipient = @recognition.recipients.first
      @recipient.update_attribute(:yammer_id, params[:recognition][:yammer_id]) if params[:recognition][:yammer_id].present?

      response_params = {
        name: "recognition_create",
        recognition_id: @recognition.id,
        person_id: @recipient.id,
        yammer_id: @recipient.yammer_id,
        recognition_url: recognition_url(@recognition)
      }
    else

      response_params = {
        name: "recognition_error",
        recognition_id: @recognition.id,
        # errors: "There was an error please refresh and try again"
        errors: @recognition.errors.full_messages.to_sentence
      }
    end

    respond_with @recognition,
      onsuccess: {
        method: "fireEvent",
        params: response_params
      }

  end

  def has_secret_password?
    key = @company.kiosk_mode_key
    key.present? && params[:code] == key
  end

  def show_help_widget?
    !iframe_viewer? &&
    ['grid', 'certificate'].none?{|a| a == action_name}
  end

  protected

  def require_user_conditionally
    actions_requiring_user_conditionally = [:index, :grid]
    actions_not_requiring_user = [:show, :share, :new, :certificate]
    if actions_requiring_user_conditionally.include?(action_name.to_sym) && has_secret_password?
      nil
    elsif actions_not_requiring_user.include?(action_name.to_sym)
      nil
    else
      require_user
    end
  end

  def recognition_params
    params
      .fetch(:recognition, {})
      .permit(
        :sender_id, :badge_id, :email, :yammer_id, :post_to_yammer_wall, :post_to_yammer_group_id, :post_to_fb_workplace, :is_private, :fb_workplace_post_id,
        :message, :sender, :badge, :reason, :experiment_value, :input_format, :request_form_id,
        recipients: [], recipient_emails: [], tag_ids: []
      ).tap do |params|
        # FIXME: an empty string is always appended with multiple select2 (issue exists elsewhere too, eg. Task#new roles select2)
        params[:tag_ids]&.delete('')
      end
  end

  def permission_denied
    if !current_user && params[:action] == "new"
      store_location
      return redirect_to(recognize_signups_path)
    end

    super
  end

  def verify_crawler
    Rails.logger.debug "Verifying Fb Crawler: #{request.remote_ip}"
    if IpChecker::FbCrawler.crawler_ip?(request.remote_ip)
      Rails.logger.debug "Verifying Fb Crawler: verified"
      @recognition ||= Recognition.find_from_param(params[:id])
      @recognition.allow_guest_access = true if @recognition.present? # defensive if recognition is deleted
    else
      Rails.logger.debug "Verifying Fb Crawler: not valid"
    end
  end

  def verify_user
    @invited_user = User.find_by_perishable_token(params[:invite])
    @pending_user_signup = @invited_user && @invited_user&.crypted_password.blank?

    if @invited_user
      @invited_user.verify! if @invited_user.invited_from_recognition? and !@invited_user.verified?
       @recognition ||= Recognition.find_from_param(params[:id])
      @recognition.allow_guest_access = true if @recognition.present?
    end
  end

  def require_network
    unless params[:network]
      if current_user
        redirect_to "/#{current_user.network}#{request.fullpath}"
      # this is a safety to a corrupt cookie issue where we would see users
      # get served the recognitions index action but not actually have a current user
      # So, if we don't have current user, redirect to root path with special parameter
      # to prevent infinite redirects.
      else
        begin
          Rails.logger.debug "WTF-0: no current user"
          if request.session["user_credentials_id"]
            Rails.logger.debug "WTF-0a: user credentials id: #{request.session["user_credentials_id"]}"
            request.session.delete("user_credentials_id")
          end
        rescue => e
          Rails.logger.debug "WTF-0b: Caught exception in require network: #{e.inspect}"
        end

        if params[:home] == "true"
          Rails.logger.debug "WTF-1: current_user: #{current_user}"
          Rails.logger.debug "WTF-2: @current_user: #{@current_user}"
          Rails.logger.debug "WTF-2b: defined?(@current_user): #{defined?(@current_user)}"
          Rails.logger.debug "WTF-3: @current_user_session: #{@current_user_session}"
          Rails.logger.debug "WTF-3b: defined?(@current_user_session): #{defined?(@current_user_session)}"
          redirect_to "/#{current_user.network}#{request.fullpath}"
        else
          redirect_to root_path(home: true)
        end
      end
    end
  end

  def streamable_recognitions
    Recognition.streamable_recognitions(user: current_user, network: params[:network], company: @company, team_id: params[:team_id], filter_by: params[:filter_by])
  end

  def redirect_personal_accounts
    if current_user.personal_account?
      redirect_to user_path(current_user) and return false
    end
  end

  # need to have specific sso functionality for recognitions#show because
  # the normal default sso handling in #require_user
  # presumes @company to be set, which by default comes from the :network param
  # recognitions#show is unscoped to a network(although really it should be scoped to senders network,
  # since it was the senders badge that was utilized)
  # So here, we need special handling to scope this actual to senders network
  def ensure_sso(company = scoped_company)
    @recognition ||= Recognition.find_from_param(params[:id])
    return if @recognition.blank?
    return if current_user.present?
    return if @recognition.is_public_to_world?
    return unless @recognition.authoritative_company.saml_enabled_and_forced?
    return if IpChecker::FbCrawler.crawler_ip?(request.remote_ip)

    store_location

    # choose recipient network when sender network
    # which is true in case of anniversary/birthday recognitions
    sso_network = @recognition.sender.system_user? ?
      @recognition.user_recipients.first.network :
      @recognition.sender.network

    redirect_to  sso_saml_index_path(network: sso_network)

  end

  # NOTE: this is related to RecognitionsHelper#recognition_nomination_task_paths
  def send_to_correct_start_form
    return if permitted_to?(:create, @recognition)
    return unless current_user.present?

    if params[:action] == "new_chromeless"
      n_path = new_chromeless_nominations_path
      t_path = new_chromeless_task_submissions_path
    else
      n_path = new_nomination_path
      t_path = new_task_submission_path
    end

    if @company.nominations_enabled?(current_user)
      redirect_to n_path
    elsif permitted_to?(:create, current_user, context: :task_submissions)
      redirect_to t_path
    else
      # Users should only see this if company admins misconfigure their account.
      # or manually access a url
      render html:"You do not have permission to send recognitions. If you believe this is an error, please contact your Company Administrator or support@recognizeapp.com.",
             layout: true
    end
  end

  def setup_recognition
    @recognition = current_user && current_user.sent_recognitions.new
  end

  def setup_tags
    @tags = Tag.none
  end

  def set_send_recognition_form
    if current_user.present?
      @jsClass = "Recognition"
      @send_recipients = recipients_from_params
    end
  end

  def recipients_from_params
    return unless params[:recipients].present?

    mapped_recipients_params = params[:recipients].kind_of?(Hash) || params[:recipients].kind_of?(ActionController::Parameters)
    if mapped_recipients_params && params[:recipients][:email].present?
      recipient = @company.users.where(email: params[:recipients][:email]).first_or_initialize
      recipient.assign_attributes(params[:recipients].permit(:first_name, :last_name))
      recipient.yammer_id = params[:recipient_yammer_id] if params[:recipient_yammer_id].present?
      recipients = Array(recipient)
    else

      if params[:recipients].kind_of?(Array)
        recipients = params[:recipients]
      else
        recipients = params[:recipients].index(',').nil? ? Array(params[:recipients]) : params[:recipients].split(',')
      end

      recipients = recipients.map do |r|
        User.find(Recognize::Application.hasher.decode(r).first)
      end
    end

    return recipients
  end

  def failure_hash_for_image_upload(message: nil, status: :unprocessable_entity)
    {
      json: { success: false, message: message }.compact,
      status: status
    }
  end

  def success_hash_for_image_upload(uploader)
    {
      json: {
        success: true,
        file: uploader.url
      }
    }
  end

  # this is for backwards compatibility
  # Note: has_secret_password? is additionally being checked because login redirection is skipped above when it's true
  def redirect_old_grid_paths
    return true unless params[:fullscreen] || has_secret_password?

    permitted_params = params.permit(:code, :team_id, :animate)
    new_grid_path = recognitions_grid_path(permitted_params)

    redirect_to(new_grid_path)
  end

  private

  def set_recognitions
    # if we're not scoped, return company wide recognitions, otherwise get all of the users recognitions
    @recognitions = streamable_recognitions.paginate(page: params[:page], per_page: @per_page_count)
  end

  def recipients_data_for_show_page(recognition)
    recognition.recipients.map do |recpt|
      recpt_id = recpt.recognize_hashid
      { name: recpt.full_name, type: recpt.class.to_s.downcase, id: recpt_id } if [User, Team].include?(recpt.class)
    end
  end
end
