class HomeController < ApplicationController
  enable_captcha only: [:sign_up]

  include CmsConcern
  cms_action :videos, :resources, :outlook, :features

  attr_accessor :awards, :pricing, :privacy_policy, :analytics,
                :terms_of_use, :contest, :gamification, :engagement,
                :customizations, :getting_started, :mobile, :slack,
                :yam_gam, :download

  def index
    @homepage_h1 = 'Customized to Your Company. Integrated Into Your Tools.'
    @homepage_image = 'pages/home-index/recognize-stream-2020.jpg'

    @user_session = UserSession.new
    @support_email = SupportEmail.new
    @support_email.type = params[:type]
    @user = find_or_initialize_user

    #the session may contain an email of user that is
    #all setup and ok to login
    if @user.ok_to_login?
      #if so, then clear out of session and present a new user
      session.delete(:email)
      session.delete(:phone)
      session.delete(:email_network)
      @user = User.new
    end
    @pageName = "marketing-home"
  end

  def videos
    @cms_videos = wp_client.videos
  end

  def demo_survey
    page_title = "Employee Recognition Report"
    page_description = "Trends and preferences towards an employee recognition and rewards program based on a survey of over 1,000 people."
  end

  def employee_recognition_programs

  end

  def reward_ideas
  end

  def is_logged_in
    render :layout => false
  end

  def rewards
    page_description = "Recognize provides an effecive employee recognition rewards app to provide a result to your employee recognition points. Visit us today."
  end

  def employee_nominations
    page_title = "Employee Award Nomination Software"
    page_description = "If you are looking for reliable employee award nomination software, visit Recognize today and learn more about the features we can offer!"
  end

  def icons
  end

  def fb_workplace
  end

  def incentives
    page_title = "Employee Incentive Program App"
    page_description = "If you are looking for a reliable employee incentive program app, visit Recognize to learn more about all of the features we have to offer!"
  end

  def resources
    @cms_resources = wp_client.resources
  end

  def office365
  end

  def outlook
    @post = wp_client.get_post(76)
  end

  def sharepoint
  end

  def engagement_report
  end

  def anniversaries
  end

  def distributed_workforce_infographic
  end

  def tour
    @user = User.new(company: Company.new)
  end

  def sign_up
    return redirect_to root_path if @current_user

    @user = find_or_initialize_user
  end

  def features
    @features = wp_client.feature_categories
  end

  def about
    @user = User.new(company: Company.new)
  end

  def extension
    @user = User.new(company: Company.new)
  end

  def why
    @user = User.new(company: Company.new)
  end

  def user_rights
  end

  def cookies_policy
  end

  def glossary
  end

  def healthcare_landing
  end

  def banking_landing
  end

  def microsoft_teams_landing
    @title = "Employee Recognition for Microsoft Teams"
    @intro_description = "Engage staff in Microsoft Teams and Office 365 with a formal on-the-spot bonus employee recognition program."
    @main_image = "pages/home-microsoft-teams-landing/dashboard.jpg"
  end

  #a view of the maintenance page for development
  def maintenance
    render action: "maintenance", layout: false
  end

  def upgrade
    if current_user.present?
      opts = {network: current_user.network}
      opts[:code] = params[:code] if params[:code].present?
      redirect_to upgrade_path(opts)
    else
      flash[:notice] = "Please login to upgrade your account"
      store_location
      redirect_to login_path
    end
  end

  def robots
    render action: "robots", layout: false
  end

  def proxy
    render action: "proxy", layout: false
  end

  def outlook_addin
    response.headers.except! 'X-Frame-Options'

    render action: "outlook_addin", layout: false
  end

  def fb_workplace_placeholder
    response.headers.except! 'X-Frame-Options'

    render action: "fb_workplace_placeholder", layout: false

  end
  protected

  def use_marketing_layout?
    true
  end

  def is_home?
    true
  end

  def find_or_initialize_user
    opts = {}
    opts[:network] = session[:email_network] if session[:email_network]
    opts[:phone] = session[:phone] if session[:phone]
    opts[:email] = session[:email] if session[:email]
    return User.find_or_initialize_by(**opts) if opts.present?

    User.new(company: Company.new)
  end
end
