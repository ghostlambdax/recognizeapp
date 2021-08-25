class SignupsController < ApplicationController
  include CachedUsersConcern
  enable_captcha only: [:create]

  skip_before_action :ensure_correct_company, only: [:fb_workplace]

  # FIXME: this needs refactoring
  #        :ensure_email_is_provided should be converted to an only: [...] instead of except: [...]
  before_action :ensure_email_is_provided, except: [:create, :confirm_email, :verify, :welcome, :finish, :requested, :recognize, :personal_interest, :fb_workplace, :password]
  before_action :ensure_email_or_phone_is_provided, only: [:password]
  before_action :load_user_using_perishable_token, only: :verify
  before_action :require_user, only: [:welcome, :finish]
  # before_action :send_to_fb_workplace_idp, only: [:fb_workplace], if: ->{ params[:network].present? }

  def create
    @user = User.new(user_params)
    if verify_recaptcha(model: @user)
      @user = User.signup!(user_params)
      unless @user.errors.any?
        refresh_cached_users!
        #new domain users will be pending signup completion
        #whereas existing domain users will be pending email verification
        if @user.pending_signup_completion?
          respond_with @user, includes: @user.company
        else
          respond_with @user, location: confirm_email_signups_path
        end
        return
      end
    end
    respond_with(@user, location: signups_path)
  end

  def full_name
    if params[:user][:network].present?
      @user = User.where(email: params[:user][:email], network: params[:user][:network]).first
    else
      @user = User.where(email: params[:user][:email]).first
    end
    @user.first_name = params[:user][:first_name]
    @user.last_name = params[:user][:last_name]
    @user.save

    respond_with @user, includes: @user.company
  end

  def password
    opts = {}
    opts[:email] = params[:user][:email] if params.dig(:user, :email).present?
    opts[:network] = params[:user][:network] if params.dig(:user, :network).present?
    opts[:phone] = params[:user][:phone] if params.dig(:user, :phone).present?
    
    # FIXME: The way this endpoint is implemented is suspect. 
    #        Can you do a raw submit to this endpoint and cause problems?
    #        There is a protection below to prevent abuse against anyone who has already 
    #        set a password. So, there is a question if there is an issue for users who have
    #        not yet set a password. This could be new users OR this could be users who
    #        just regularly sign in via OAuth or SSO. 
    #        Also, FYI, the _recognition_signup.html.erb partial also protects against showing
    #        the form for companies that have don't have passwords enabled, which is something, but still doesn't fully protect
    #        against raw submissions
    @user = (opts[:email] ? User : User.search_by_phone(opts[:phone])).where(**opts).first

    # don't proceed if the user has already set a password
    raise_invalid_request_to_set_password! if @user.crypted_password.present?

    @user.first_name = params[:user][:first_name] if params[:user].has_key?(:first_name)
    @user.last_name = params[:user][:last_name] if params[:user].has_key?(:last_name)
    @user.password = params[:user][:password]
    @user.terms_and_conditions = params[:user][:terms_and_conditions]
    @user.validate_terms_and_conditions = true
    @user.force_password_validation = true
    @user.password_strength_check = true
    @user.save

    if @user.errors.blank?
      InboundEmail.release!(@user)

      if session[:ok_to_verify]
        session.delete(:ok_to_verify)
        @user.verify! if !@user.verified?
        @user.reset_perishable_token!      
      end

      @user.set_status!(:active)
      UserSession.create!(@user)
    end

    flash[:newly_signedup] = true

    fb_workplace_sesh = FbWorkplace::SessionVars.new(@user, session)

    if fb_workplace_sesh.should_handle?
      fb_workplace_sesh.assign_workplace_session_vars
      url = fb_workplace_sesh.redirect_url
    elsif @user.personal_account?
      url = user_path(@user, refresh: true)
    else
      url = welcome_path(network: @user.network, refresh: true)
    end
    respond_with @user, location: url
  end

  def confirm_email
  end

  # NOTES: 
  #    - if logged in as user with token, we verify immediately (this is case with first signup user who clicks verification link while logged in)
  #    - if not logged in, we'll create a user sesion
  def verify

    # edge case if you click a verify link
    # and are logged in as someone else
    if current_user
      if current_user == @user
        @user.verify!
        @user.reset_perishable_token!
      else
        # FIXME: we shouldn't allow this
        #        we should instead present a warning message
        #        #3464 - https://github.com/Recognize/recognize/issues/3464
        logout_current_user
      end
    else
      if @user.ok_to_login?
        flash[:newly_signedup] = true
        UserSession.create!(@user)
      else
        session[:email] = @user.email
        session[:phone] = @user.phone
        session[:email_network] = @user.network
        # we are not going to verify immediately to
        # 1. handle link previews that will do GET requests on this endpoint
        # 2. wait until the user actually sets the password
        session[:ok_to_verify] = true
      end
    end

    url = if @user.personal_account? and @user.ok_to_login?
            user_path(@user)
          elsif @user.company.disable_passwords?
            identity_provider_path(network: @user.network)
          else 
            # I think if we get to here, mainly its the case
            # where the user still needs to set a password
            # or possibly first/last name and then password
            # It think if you go here and you're logged in, 
            # you will redirect to the stream page (i think...)
            sign_up_path
          end

    redirect_to url
  end

  def requested
    @encoded_email = params[:id] #Base64 encoded
  end

  def personal_interest
    @sr = SignupRequest.find_by_email(Base64.decode64(params[:email].to_s))
    if params[:interested] == "yes"
      @sr.update_attribute(:pricing, "personal")
    end
    head :ok
  end

  def recognize
  end

  def fb_workplace
    # fb workplace params come from GET params
    # when a user links their account by clicking button in Workchat
    if params[:fb_workplace_params].present?
      raw_fb_workplace_params = params[:fb_workplace_params]
      fb_workplace_params = ActionController::Parameters.new(JSON.parse(Base64.decode64(raw_fb_workplace_params)))
      unclaimed_token = FbWorkplaceUnclaimedToken.where(community_id: fb_workplace_params[:fb_workplace_community_id]).first

      # Add unclaimed token to session if user installs integration but doesn't
      # complete linking to Recognize account. When this happens, we stash
      # the community_id and token in FbWorkplaceUnclaimedTokens table.
      # When user separately interacts with the bot, it will prompt them to connect
      # The connect button takes them here and passes community id as parameter
      # So, we need to detect if there is an unclaimed token for this community id
      # And if so, place the correct parameters in session - so it can pick up where it left off.
      if unclaimed_token.present?
        fb_workplace_params[:fb_workplace_token] = unclaimed_token.token.to_s
        raw_fb_workplace_params = Base64.encode64(fb_workplace_params.to_json)
      end
  
      session[:fb_workplace_params] = raw_fb_workplace_params
      if current_user
        fb_sesh = FbWorkplace::SessionVars.new(current_user, session)
        fb_sesh.assign_workplace_session_vars
        return redirect_to fb_sesh.redirect_url
      else
        # autoforward via SSO when SSO is present
        company = Company.find_by_fb_workplace_community_id(fb_workplace_params[:fb_workplace_community_id])
        if company&.saml_enabled_and_forced?
          url = sso_saml_index_path(network: company.domain)
          redirect_to url
        end
      end

    end
  end

  def yammer
  end

  protected
  def handle_blacklisted_emails
    if params[:user] and params[:user][:email] and User.blacklisted_email?(params[:user][:email])
      sr = SignupRequest.create(email: params[:user][:email])
      respond_with sr, location: requested_signups_path(id: Base64.encode64(sr.email))
    end
  end
  #TODO: i removed the before_action that calls this, but perhaps in the future we
  #      will want to use this for the paid model...
  # def restrict_to_beta_domains
  #   if params[:user] and params[:user][:email].present? and User.new(email: params[:user][:email]).valid?
  #     e = params[:user][:email]
  #     if !Company.beta_domain?(e.split("@")[1]) and !User.blacklisted_email?(e)
  #       sr = SignupRequest.find_or_initialize_by(email: e, pricing: params[:pricing])

  #       if sr.persisted?
  #         flash[:notice] = "You've already signed up with that email. We'll contact you shortly."
  #       else
  #         sr.save!
  #         SystemNotifier.delay.signup_request(sr)
  #       end

  #       respond_with sr, location: requested_signups_path
  #       return false
  #     end
  #   end
  # end

  def ensure_email_or_phone_is_provided
    return if params[:user] && (params[:user][:email].present? || params[:user][:phone].present?)
    user = User.new
    user.errors.add(:base, "Login is missing, Please return to homepage and try again.")
    respond_with user, location: root_path
  end

  def ensure_email_is_provided
    unless params[:user] and params[:user][:email]
      user = User.new
      user.errors.add(:base, "Email is missing, Please return to homepage and enter email address")
      respond_with user, location: root_path
    end
  end

  def load_user_using_perishable_token
    # @user = User.find_using_perishable_token(params[:id])
    @user = User.where(perishable_token: params[:id]).first
    unless @user
      flash[:notice] = "This link has expired.  Please resubmit the password reset form and we will send you an email to access your account"
      redirect_to new_password_reset_path  and return false
    end
  end

  def send_to_fb_workplace_idp
    redirect_to identity_provider_path(network: params[:network], fb_workplace_params: params[:fb_workplace_params])
  end

  private

  def user_params
    params
      .require(:user)
      .permit(:email, :network, :terms_and_conditions)
  end

  def raise_invalid_request_to_set_password!
    raise ActionController::BadRequest.new(), "Passwords may not be set here if you've already set a password"    
  end
end
