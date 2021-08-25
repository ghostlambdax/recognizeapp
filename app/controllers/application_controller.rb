class ApplicationController < ActionController::Base
  protect_from_forgery
  serialization_scope :view_context

  helper_method :current_user, :ajax_safe_redirect

  before_action :set_gon_host
  before_action :set_exception_data
  before_action :set_locale
  before_action :set_company
  before_action :reject_improper_redirect_params
  before_action :set_superuser
  before_action :ensure_correct_company, except: [:routing_error]
  before_action :load_yammer_client

  before_action :set_chat_thread

  #tell DeclarativeAuthorization which user to evaluate for permissioning
  before_action { |c| Authorization.current_user = c.current_user }
  before_action :miniprofiler
  after_action :allow_iframe
  after_action :track_request

  # no longer automatically added since v5.0.0
  before_action :set_paper_trail_whodunnit
  around_action :use_user_timezone

  include CaptchaConcern
  include UserSessionsHelper
  include ApiHelper
  include ExceptionHelper
  include ActionView::RecordIdentifier
  include ThirdPartyIframe
  include UrlHelper
  include UsersUrlConcern

  require 'will_paginate/array'

  filter_access_to :all

  self.responder = ApplicationResponder
  respond_to :html, :js, :json

  rescue_from YammerClient::Unauthorized, with: :handle_oauth_error
  rescue_from Authorization::NotAuthorized, with: :handle_unauthorized

  def set_gon_host
    gon.recognize_host = "https://"+Rails.application.config.host
  end

  def ajax_safe_redirect(url)
    if request.xhr?
      render :js => "window.location = '#{CGI.unescape(url)}'"
    else
      redirect_to CGI.unescape(url)
    end
  end

  def set_chat_thread
    if current_user.blank?
      @chat_thread = ChatThread.new
    end
  end

  def set_locale
    I18n.locale = (locale_from_params || (current_user && current_user.locale) || I18n.default_locale)
  end

  def locale_from_params
    if params[:locale].present?
      if params[:locale].scan(/locale/).length >= 1
        params[:locale].gsub('?locale=en-GB','')
      else
        params[:locale].gsub(/\?.*/,'')
      end
    end
  end

  # This links into UrlHelperCallWithDefault
  PERSISTENT_PARAMS = %i[locale network dept referrer viewer popup entity_id].freeze
  def default_url_options
    static_params = PERSISTENT_PARAMS.without(:locale)
    params.permit(static_params).to_h.symbolize_keys.tap do |opts|
      opts[:locale] = I18n.locale unless I18n.locale == I18n.default_locale
    end
  end

  def routing_error
    if current_user and !params[:network].casecmp?(current_user.network) and !params[:network].casecmp?("uploads")
      Rails.logger.info "AppController#routing_error - first conditional"
      # if params[:network] is an actual domain, swap it out
      # otherwise, add the correct network in(useful for getting to proper routes without knowledge of which network is correct)
      # eg from sharepoint
      u = if Company.exists?(domain: params[:network])
            request.fullpath.gsub(params[:network], current_user.network)
          else
            "/#{current_user.network}#{request.fullpath}"
          end
      redirect_to u

    elsif (match = request.path.match(/^(.*)\/saml\/sso(.*)/))
      network = match[1]
      intended_page = match[2]
      uri = URI.parse("#{network}#{intended_page}")
      # query_params = params.slice("viewer", "referrer")
      # uri.query = URI.encode_www_form(query_params.to_a)
      uri.query = params.permit(:viewer, :referrer).to_query
      
      if current_user
        redirect_to uri.to_s

      else
        saml_url = network + "/saml/sso"

        if iframe_viewer?

          decoder = Recognize::OutlookJwtDecoder.new(params[:outlook_identity_token])
          decoder.validate
          user = User.where(network: network.gsub(/^\//, ''), outlook_identity_token: decoder.unique_id).first

          @popup_url = if decoder.valid? && user.present?
                         false
                       else
                         "https://#{Rails.application.config.host}#{saml_url}?close_on_open=true&outlook_identity_token=#{params[:outlook_identity_token]}&popup=#{params[:viewer]}"
                       end

          render template: "saml/placeholder"

        else
          # company = Company.find_by(domain: network.gsub(/^\//, ''))
          store_location uri.to_s
          redirect_to saml_url
        end
      end

    # NOTE: 11/2/2015 - the original intention here was to be able to have routes that could be specified without a network
    #       if the user is logged in, they'll be redirected appropriately
    #       if the user is not logged in, they'll be redirected to sign in page and then redirected to correct page
    #       However, this was problematic with routes like /rewards which has both a marketing page and a logged in
    #       page.
    #       So instead, I'm switching to a model where you can specify /redirect/:path,
    #       and then the behavior above will kick in.
    elsif request.path.match(/\/redirect/) && valid_route_but_without_network?
      Rails.logger.info "AppController#routing error - redirect to valid route without network: #{recognize_signups_path}"
      # we're trying to go to a valid route but we haven't specified a network, and we're not logged in
      # so sign up/in page with ability to redirect to original route
      store_location
      if iframe_viewer?
        if sharepoint_viewer? || outlook_viewer?
          redirect_to office365_path
        else
          c = CompanyDomain.where(domain: params[:referrer]).first.try(:company)
          if c.present?
            redirect_to identity_provider_path(network: c.domain)
          else
            flash.now[:error] = "This iframe url is not valid. Please check the format and parameters. If you have any questions, please contact out support."
            Rails.logger.info "Tried to iframe with invalid referrer: #{params.inspect}"
            render file: Rails.root.join('public', '404.html'), :status => 404
            # render file: "public/404", :status => 404
          end
        end
      else
        redirect_to recognize_signups_path
      end
    elsif (path = valid_route_without_redirect_keyword?)
      Rails.logger.info "AppController#routing error - redirect to valid route without redirect keywork:#{path}"
      redirect_to path
    else
      render file: Rails.root.join('public', '404.html'), :status => 404
      # render file: "public/404", status: 404
    end
  end

  def permission_denied
    if current_user
      msg = "Sorry. You do not have permission to access that page. " +
            view_context.link_to("Go back to where you came from", :back)
      render html: msg.html_safe, layout: true, status: 401
    else
      flash[:error] = "You must login to access that page"
      #use helpers/user_sessions_helper
      #so we can store location and redirect back upon login
      require_user
    end
    return false
  end


  def url_options
    super().merge(params.slice("viewer", "referrer").to_unsafe_h.symbolize_keys)
  end

  def recaptcha_enabled_for_company?(network)
    return false if network.blank?

    Company.find_by(domain: network)&.settings&.recaptcha?
  end

  private

  def amp_request?
    request.format.try(:amp?)
  end

  def fb_workplace_viewer?
    params[:viewer] == "fb_workplace"
  end
  helper_method :fb_workplace_viewer?

  def outlook_popup?
    params[:popup] == "outlook"
  end
  helper_method :outlook_popup?

  def outlook_viewer?
    params[:viewer] == "outlook"
  end
  helper_method :outlook_viewer?

  def sharepoint_viewer?
    params[:viewer] == "sharepoint"
  end
  helper_method :sharepoint_viewer?

  def iframe_viewer?
    raise "Invalid viewer" if params[:viewer] == true # hard fail if this ever happens
    %w[sharepoint outlook intranet chrome safari fb_workplace yammer ms_teams].include?(params[:viewer].downcase) if params[:viewer].present?
  end
  helper_method :iframe_viewer?

  def ms_teams_viewer?
    params[:viewer] == "ms_teams"
  end
  helper_method :ms_teams_viewer?

  def ms_teams_personal_tab?
    ms_teams_viewer? && params[:entity_id] == MsTeamsController::PERSONAL_TAB_ENTITY_ID
  end
  helper_method :ms_teams_personal_tab?

  def ios_viewer?
    params[:viewer] == "ios"
  end
  helper_method :ios_viewer?

  def popup?
    %w[sharepoint outlook intranet chrome safari yammer].include?(params[:popup].downcase) if params[:popup].present?
  end
  helper_method :popup?



  # See note above in routing error.
  def valid_route_but_without_network?
    path = request.path.gsub(/^\/redirect/, '/recognizeapp.com')
    route_params = Rails.application.routes.recognize_path(path)
    return route_params[:action] != "routing_error"
  end

  def valid_route_without_redirect_keyword?
    path = request.fullpath.gsub(/redirect\//,'')
    if Rails.application.routes.recognize_path(path)[:action] != "routing_error"
      return path
    else
      return false
    end
  end

  def sendable_nomination_badges
    @badges ||= current_user.sendable_nomination_badges
  end

  def sendable_recognition_badges
    @badges ||= current_user.sendable_recognition_badges
  end
  helper_method :sendable_nomination_badges, :sendable_recognition_badges

  def set_company
    @company = if current_user
                 if current_user.admin? && !current_user.director? && params[:network].present?
                   Company.where(domain: params[:network]).first
                 elsif current_user.director? && params[:network].present?
                   current_user.company.family.detect{|c| c.domain.casecmp?(params[:network])}
                 else
                   current_user.company
                 end
               else
                 Company.where(domain: params[:network]).first if params[:network].present?
               end
  end

  def scoped_company
    @company ||= set_company
  end

  def load_yammer_client(user = current_user)
    token = user ? user.yammer_token : nil
    Recognize::Application.yammer_client = YammerClient::Client.new(token, current_user)
  end

  def handle_oauth_error(_exception)
    Rails.logger.warn "Handling OAUTH error for user: #{current_user.try(:id) || 'no user'}"
    # Recognize::Application.yammer_client.handle_unauthorized(_exception, current_user)
    flash.now[:error] = "There was an error with your Yammer Authentication.  If this is an error, please reauthenticate."
    # render action: params[:action]
    url = "/auth/yammer"
    if request.xhr?
      authenticity_token_hidden_field = "<input id='authenticity_token' name='authenticity_token' type='hidden' value= #{SecureRandom.base64(32)}/>"
      auth_yammer_post_request = "const form = document.createElement('form');form.method = 'post';form.action = #{url};form.append(#{authenticity_token_hidden_field});document.body.appendChild(form); form.submit();"
      render js: "Swal.fire({showCancelButton:true,cancelButtonText:'Not now',confirmButtonText: 'Authenticate',title:'Your yammer authentication has expired',text: 'Please reauthenticate for full Yammer functionality'}, function(){#{auth_yammer_post_request}})", status: 401
    else
      redirect_to url
    end
  end

  def handle_unauthorized(exception)
    render plain: exception.message, status: 401
  end

  def miniprofiler
    if params[:debug] and defined?(Rack::MiniProfiler)
      Rack::MiniProfiler.authorize_request
    end
  end

  # track events after redirect
  def flash_track_event(event, props)
    flash[:trackEvents] ||= []
    flash[:trackEvents] << {event: event, properties: props}
  end

  def flash_add_prop_to_page_event(props)
    flash[:trackProperty] = props
  end

  def set_superuser
    if current_user and session.has_key?(:superuser)
      current_user.acting_as_superuser = session[:superuser]
    end
  end

  def ensure_correct_company
    if current_user and params[:network].present? and !current_user.admin? and !current_user.network.casecmp?(params[:network])
      if !current_user.director? || !current_user.domain_in_family?(params[:network])
        redirect_to request.fullpath.gsub(params[:network], current_user.network)
      end
    end
  end

  def allow_iframe

    if params[:viewer]
      case params[:viewer]
        when "ms_teams"
          allow_ms_teams_iframe
        when "fb_workplace"
          allow_fb_workplace_iframe
        when "intranet"
          allow_intranet_iframe
        when "sharepoint"
          allow_sharepoint_iframe
        when "outlook"
          allow_outlook_iframe
        when "chrome"
          allow_chrome_ext_iframe
        else
          allow_yammer_iframe
      end
    else
      # allow controllers to skip adding this automatically
      # see HomeController#outlook_addin
      if current_user
        response.headers['X-Frame-Options'] = 'ALLOW-FROM https://www.yammer.com' if response.headers.has_key?('X-Frame-Options')
      end
    end

  end

  def render_people_picker(_people, form_object, url)
    # FIXME: this should really not use @team
    render partial: "people/picker", locals: {people: @team.company.users.not_disabled, form_object: form_object, url: url}
  end

  def use_marketing_layout?
    current_user.blank? ? true : false
  end
  helper_method :use_marketing_layout?

  def is_home?
    false
  end
  helper_method :is_home?

  def track_request
    if current_user.present? && defined?(::Analytics)
      ::Analytics.track(
        user_id: current_user.id,
        event: "PAGE: /#{controller_name}/#{action_name}",
        properties: {
          controller: controller_name,
          network: current_user.network,
          admin_dashboard_enabled: current_user.company.allow_admin_dashboard,
          yammer: current_user.auth_with_yammer?,
          custom_badges: current_user.company.custom_badges_enabled?,
          has_subscription: current_user.company.subscription.present?,
          using_oauth: using_oauth?,
          user_agent: request.env["HTTP_USER_AGENT"],
          viewer: params[:viewer],
          fullscreen: params[:fullscreen] # deprecated
        })
    end
  end

  def self.show_upgrade_banner(opts = {})
    raise "You cannot specify if conditional, it will be overriden" if opts.has_key?(:if)
    before_action -> { @show_upgrade_banner = true }, opts.merge(if: ->{current_user && !current_user.subscribed_account?})
  end

  def reject_improper_redirect_params
    if params[:redirect].present? && params[:redirect].match(/^http/)
      uri = URI.parse(CGI.unescape(params[:redirect]))
      host = Rails.application.config.host
      host.gsub!(/\:[0-9]+/,'') unless Rails.env.production? # strip port number for local dev when comparing host

      proper_redirect = false
      proper_redirect ||= uri.host == "yammer.com" || uri.host == "www.yammer.com"
      proper_redirect ||= uri.host == host
      render file: Rails.root.join('public', '406.html'), :status => 406 unless proper_redirect
      # render file: "public/406", :status => 406 unless proper_redirect
    end
  end

  # The following method overrides PaperTrail's same named method.
  # PaperTrail is enabled by default for all controllers. Here, we disable it for all controllers globally.
  # Override this method to set it to true to enable PaperTrail in controllers where required.
  def paper_trail_enabled_for_controller
    false
  end

  def use_user_timezone
    user_timezone = current_user&.timezone_with_company_default
    Time.use_zone(user_timezone) { yield }
  end

  def show_help_widget?
    !iframe_viewer?
  end
  helper_method :show_help_widget?

  def set_gon_stream_comments_and_approvals_path
    gon.comments_async_endpoint = stream_comments_path
    gon.approvals_async_endpoint = stream_approvals_path
  end

  def user_for_paper_trail
    current_user.present? ? current_user.id : User.system_user.id
  end
end
