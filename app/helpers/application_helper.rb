module ApplicationHelper
  #re: page_name, js_class helpers
  #these drop variables into the <body> tag of the layout(note: there are multiple layouts: application, user_stream)
  #here we opt to use content_for rather than a before filter
  #the idea is that we want the views to determine what variables to drop.
  #this may seem not dry, and you need to specify the same thing in multiple views, but its more explicit
  #and as well, we avoid the problem where we have to worry about which view is rendered in which action
  #so if an action changes the view, then we need to update the before_action as well
  #this way, whichever action needs to render a view, we'll drop the variables that apply to that view
  #and are worry free!
  #
  ACTIVE_JOB_DJ_CLASS = ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper

  def feather_icon(icon, html_opts = {})
    @page_has_icons = true
    html_opts['data-feather'] = icon
    return content_tag(:i, '', html_opts)
  end

  def due_invoice
    return false unless current_user&.company_admin?

    unpaid_invoices = current_user.company.invoice_documents.unpaid.upcoming
    unpaid_invoices.first
  end

  def feature_permitted?(feature, skip_user_check: false)
    Subscription.feature_permitted?(@company, current_user, feature, skip_user_check: skip_user_check)
  end

  SHORT_LANGUAGES = ['ar', 'zh-Hans', 'zh-TW', 'cs', 'en-AU', 'en-GB', 'de', 'ja', 'ko', 'pl']
  def is_long_language_css_klass
    if current_user && !SHORT_LANGUAGES.include?(current_user.locale)
      "long-language"
    end
  end

  def numeric_delta_converter(previous_value, final_value)
    Delta.new(previous_value, final_value)
  end

  def is_amp?
    request.format.symbol == :amp
  end

  def lazy_image_tag(src, options = {})
    if is_amp?
      if src.blank?
        src = options.dig(:data, :src) || ""
      end

      width = options[:width].present? ? options[:width] : 480
      height = options[:height].present? ? options[:height] : 320

      src = image_path(src)

      tag = "<amp-img src='#{src}' alt='#{options[:alt]}' class='#{options[:class]}' height='#{height}' width='#{width}' layout='responsive'></amp-img>".html_safe
    else
      lazy_options = options.merge({data: {src: image_path(src)}})
      lazy_options[:class] ||= ""
      lazy_options[:class] << " lazy maxWidth100"
      tag = image_tag("", lazy_options)
    end

    return tag
  end

  def js_class
    content_for(:js_class)
  end

  def content_for_stream_page
    content_for(:page_name) {"stream"}
    content_for(:js_class) {"Stream"}
  end

  VOWELS = ["a", "e", "i", "o", "u", "y"]
  def add_preceding_article(string)
    article = VOWELS.include?( string[0].downcase ) ? "an" : "a"
    "#{article} #{string}"
  end

  def render_flash(opts={})
    locals = {flash: flash, include_errors: opts[:include_errors]}
    render partial: "layouts/flash", locals: locals
  end

  #passed in user can be a User object or a UserLite object
  #as long as it responds to slug
  def link_to_user(user, opts={})
    avatar = AvatarAttachment.find_by_owner_id(user.id)
    img = image_tag(avatar.small_thumb.url, class: "profile-pic pull-left", style: "height:20px;padding-right:5px") if avatar
    link_to img.to_s+user.full_name, user_path(user.slug, network: user.network)
  end

  def user_recognition_path(user, opts={})
    url_opts = {recipients: [user.recognize_hashid], recipient_network: user.network}.merge(opts)
    new_recognition_path(url_opts)
  end

  def user_recognition_url(user, opts={})
    chromeless = opts.delete(:chromeless)

    if user.persisted?
      url_opts = {recipients: [user.recognize_hashid], network: user.network}
    else
      url_opts = {recipients: {email: user.email, first_name: user.first_name, last_name: user.last_name}}
    end

    url_opts[:recipient_yammer_id] = user.yammer_id if user.yammer_id.present?
    url_opts.merge!(opts)

    chromeless ? new_chromeless_recognitions_url(url_opts) : new_recognition_url(url_opts)
  end

  def link_to_yammer(text = "Sign in with Yammer", opts={})

    url_opts = {provider: "yammer"}.merge(opts[:params] || {})
    url_opts[:network] = params[:network] if params[:network].present?
    url_opts[:redirect] = opts[:redirect] || params[:redirect]

    # Does this need to be here? check oauth_concern for redundant assignment.
    if outlook_viewer?
      url_opts[:outlook_successful_auth] = true
    end

    class_names = opts[:class].present? ? "#{opts[:class]}" : "button-yammer-signup button"

    link_to text, remote_auth_url(url_opts), method: :post, class: class_names
  end

  def link_to_google(text = "Sign in with Google", opts={}, &block)
    url_opts = {provider: "google_oauth2"}.merge(opts[:params] || {})
    url_opts[:network] = params[:network] if params[:network].present?
    url_opts[:redirect] = opts[:redirect] || params[:redirect]

    class_names = opts[:class].present? ? "#{opts[:class]}" : ""

    if block_given?
      link_to remote_auth_url( url_opts ), method: :post, class: class_names do
        image_tag "3p/google-login.png" do
          yield
        end
      end
    else
      link_to remote_auth_url( url_opts ), method: :post, class: class_names do
        image_tag "3p/google-login.png"
      end
    end
  end
  alias_method :link_to_google_oauth2, :link_to_google

  # be careful when adding perms about which ones need to be scopes to graph.microsoft.com
  MICROSOFT_DEFAULT_SCOPES = ["offline_access", "https://graph.microsoft.com/User.Read"]
  MICROSOFT_ADMIN_SCOPES = ['User.ReadBasic.All', 'Group.Read.All', 'Directory.Read.All'].map{|s| "https://graph.microsoft.com/#{s}"}
  def link_to_o365(text = "Sign in with Microsoft", opts={}, &block)
    class_names = (opts[:button] == false) ? "#{opts[:class]}" : "button-microsoft-graph-signup button #{opts[:class]}"
    class_names << " o365-auth-link" if iframe_viewer?

    # TODO: why is this way more complicated than link_to_yammer?
    options = {}
    options[:class] = class_names

    url_options = {provider: :microsoft_graph}
    if opts[:admin_consent]
      url_options[:scope] = (MICROSOFT_DEFAULT_SCOPES + MICROSOFT_ADMIN_SCOPES).join(" ")
    else
      url_options[:scope] = opts[:scope] if opts[:scope].present?
    end

    url_options[:popup] = params[:popup] if params[:popup].present?
    url_options[:login_hint] = params[:email] if params[:email].present? && params[:email].include?("@")
    url_options[:redirect] = opts[:redirect] || params[:redirect]

    if url_options[:redirect].blank?
      if opts[:params] && opts[:params][:redirect]
        url_options[:redirect] = opts[:params][:redirect]
      else
        url_options[:redirect] = session[:return_to] || root_path
      end
    end

    if opts[:params].present? && opts[:params][:outlook_identity_token].present?
      url_options[:outlook_identity_token] = opts[:params][:outlook_identity_token]
    end

    url_options[:network] = opts[:network] || (opts[:params] && opts[:params][:network]) || params[:network]
    options[:method] = :post

    link_to text, remote_auth_url(url_options), options
  end
  alias_method :link_to_microsoft_graph, :link_to_o365

  def link_to_saml(text = t('saml.sign_in'), opts = {})
    class_names = opts[:class].present? ? "#{opts[:class]}" : "button button-primary"
    url_opts = opts[:network].present? ? {network: opts[:network]} : {}
    url_opts[:outlook_identity_token] = opts[:outlook_identity_token] if opts[:outlook_identity_token].present?
    link_to text, sso_saml_index_path(url_opts), {class: class_names}
  end

  def is_live_production_server?
    Recognize::Application.config.host == "recognizeapp.com"
  end

  def use_production_analytics?
    (is_live_production_server? and Rails.env.production? and (!current_user or (current_user and current_user.company.domain != "recognizeapp.com")))
  end

  def time_from_yearweek(yearweek)
    m = yearweek.to_s.match(/^([0-9]{4})([0-9]{2})$/)
    year, week = m[1].to_i, m[2].to_i
    Date.commercial(year, week).to_time.to_i*1000
  end

  def percent(count, total)
    p = (count / total.to_f)*100
    precision = p < 1 ? 2 : 0
    number_to_percentage(p, precision: precision)
  end

  def show_toggle(condition, title, opts={}, &block)
    render(partial: "layouts/toggle", locals: {condition: condition, title: title, opts: opts, block: block})
  end

  def formatted_price(price)
    if price.present?
      "%g" % (price / 1.0)
    end
  end

  def company_teams_json
    (@company && @company.teams.present? ? @company.teams : []).to_json.html_safe
  end

  def has_theme?
    if @company.present?
      @company.has_theme?
    end
  end

  # FIXME:
  # these should really be refactored to return the html with all
  # of the conditions. See the usage of these methods. There is 
  # duplication that should be DRY'd up into these helpers
  def company_customization_primary_logo
    @company && @company.customizations&.primary_header_logo
  end
  
  def company_customization_secondary_logo
    @company && @company.customizations&.secondary_header_logo
  end
  
  def body_classes
    classes = []
    classes << page_class
    classes << is_long_language_css_klass
    classes << "logout" if !current_user
    classes << "has-theme" if has_theme?
    classes << "viewer-#{params[:viewer]}" if params["viewer"].present?

    if current_user.present?
      classes << "subscription-active" if current_user.subscribed_account?
      classes << 'admin-privilege' if permitted_to?(:show, current_user.company)
    end

    classes << "no-nav" unless show_header?
    classes << "no-teams" if page_id == "recognitions-index" && !allow_teams?
    classes.join(" ")
  end

  def html_classes
    classes = []
    classes << "fullscreen" if is_grid_view?
    classes << "marketing" if use_marketing_manifests?
    classes << 'invoice-due' if due_invoice.present?
    classes.join(" ")
  end

  def language_direction
    I18n.locale== :ar ? 'rtl' : 'ltr'
  end

  def company_family_set(company = @company)
    company.family.map{|c| [c.name, c.domain] }
  end

  def company_family_options_for_select(company = @company)
    options_for_select(company_family_set(company), (params[:dept] || current_user.network))
  end

  def show_header?
    !(ios_viewer? || ms_teams_configurable_tab?)
  end

  def show_upgrade_banner?
    @show_upgrade_banner
  end

  def formatted_phone(phone)
    return nil unless phone.present?
    return phone if Recognize::Application.twilio_client.kind_of?(Recognize::Application::TwilioMockClient)

    return (Twilio::PhoneNumber.format(phone) rescue phone) || phone
  end

  def sending_limit_scope_select(name, selected = nil, opts={})
    if @company.allow_send_limit_scope_selection?
      # options = options_for_select([["Recognitions", Recognition::SCOPE_LIMIT_BY_RECOGNITIONS, ], ["Recipients", Recognition::SCOPE_LIMIT_BY_USERS]])
      options = options_for_select(Recognition::LimitScope.options_for_select, selected)
      style = @company.allow_nominations? ? "display: none;width:150px;" : "width: 150px;"
      select_tag(name, options, opts.merge({style: style}))
    end
  end

  def company_theme_id
    @company.company_theme_id
  end

  # this is meant for momentjs interpretation
  def localized_js_slashdate_format
    I18n.t('date.formats.js_slash_date')
  end

  def show_points(company = @company)
    unless company.hide_points?
      yield
    end
  end

  def attachment_uploader(form, field, opts = {} )
    render("layouts/attachment_uploader", form: form, field: field, opts: opts)
  end

  def autosave_setting_form
    form_for @company.settings, url: company_admin_settings_path, remote: true, html: {class: "autosave-setting-form"} do |f|
      yield f
    end
  end


  def link_to_add_fields(name, f, association)
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.singularize + "_fields", form: builder)
    end
    link_to(name, 'javascript://', class: "add_#{association.to_s.singularize}", data: {id: id, fields: fields.gsub("\n", "")})
  end

  def use_landing_page_menu
    @use_landing_page_menu == true
  end

  def use_marketing_manifests?
    is_home? || (@use_marketing_manifest == true)
  end

  def outlook_successful_auth?
    params[:outlook_successful_auth].present?
  end

  def schedule_demo_link(opts = {})
    render "layouts/schedule_demo_link", opts
  end

  # NOTE: sister method in OAuthConcern
  def mobile_viewer?
    mobile_param = params[:mobile]
    viewer = params[:viewer]

    (mobile_param == 'true') || (viewer == 'android') || (viewer == 'ios')
  end

  def show_cookie?
    !is_grid_view? && !Rails.env.test? && (current_user.blank? || !current_user.subscribed_account?) && !iframe_viewer? && !mobile_viewer? &&
    params[:referrer] != 'fb_workplace'
  end

  def litatable_format_function(datatable)
    render partial: "litatables/export_format_functions", formats: [:js], locals: {datatable: datatable}
  end

  def chrome_extension_url
    "https://chrome.google.com/webstore/detail/recognize/khonmmgfpdbncbianbikkhchhgleeako"
  end

  def explanation_bar
    content_tag(:div, class: "well marginVertical10 width100") do
      concat(image_tag("chrome/header/help.png", class: "left marginRight10"))
      yield
    end
  end

  def is_grid_view?
    action_name == 'grid' && controller_name == 'recognitions'
  end

  # Method to make sure we can safely output a url that will be used to redirect somewhere
  # For instance, to javascript that will ultimately redirect somewhere
  # https://product.reverb.com/stay-safe-while-using-html-safe-in-rails-9e368836fac1
  def escape_redirect(url)
    uri = URI.parse(url)
    "".html_safe + uri.path + '?' + uri.query.html_safe
  end

  # special link_to that will manipulate the final link
  # Allows views to specify whether target should be blank
  # and if so, we'll exclude certain query parameters (such as viewer and entity_id)
  # https://apidock.com/rails/ActionView/Helpers/UrlHelper/link_to
  # This only supports the signature:
  #     link_to(name, url, html_options = {})
  def viewer_link_to(name, url, is_target_blank, html_options = {})
    uri = Addressable::URI.parse(url)
    uri.query_values = uri.query_values.except("viewer", "entity_id").presence if is_target_blank
    html_options[:target] = "_blank" if is_target_blank
    link_to(name, uri.to_s, html_options)
  end

  def form_recaptcha_tags
    if Recaptcha.configuration.site_key.present?
      invisible_recaptcha_tags(ui: :invisible, callback: "captchaSuccessCallback", error_callback: 'captchaErrorCallback', script: false).html_safe
    end
  end

  def load_push_notification_code?
    return false # disable completely for now until we reimplement the client side to be more robust
    return false unless current_user.present? # don't do it, if not logged in
    return false if current_user.acting_as_superuser # don't do it, if we're impersonating
    return false if iframe_viewer? # don't do it, if we're in any kind of iframe viewer
    return true
  end

  def pagelet(endpoint)
    content_tag(:div, class: "pagelet", data: {endpoint: endpoint}) do
      content_tag(:div, class: "loading-wrapper", style: "width: 100%;text-align:center") do
        image_tag "icons/outlook-progress.gif"
      end
    end
  end
end
