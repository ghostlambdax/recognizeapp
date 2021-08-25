#####################################################################################################################
#
# Possible states of a user:
#
# active:
#    a user is all signed up and fully able to use all features their role has access to
#
#  invited:
#    an email has been sent to this users email address and no further action has yet been taken by the invitee
#
#  invited_from_recognition:
#    you can recognize people by their email address.  This poses a chicken/egg argument about whether to create
#    the recognition first or user first.  Can't create the recognition first, but creating the user first without
#    knowing if the recognition succeeds is a bit of a problem.  Also, we want to have a special invite/recognition
#    email and not send the default invite and recognition emails.
#
#  pending email verification:
#    a user has completed signup of there own volition and they have not yet verified their email address.
#    Only applies to users that have signed up after the first user.
#
#  pending invite:
#    we can add users and not immediately send an invitation email.
#    once we send the invitation email, they will be moved to "invited" status.
#
#  NOTE: when a user verifies their email from "pending email verification", "invited", or "invited from recognition"
#            the user will go to "pending_signup_completion", as a temporary state until they set their password
#            once they put in their password, they become "active"
#
#  pending signup completion:
#    a user has initiated signup and is the first user for their company but has not yet completed signup.
#    They are considered to have completed signup once they have saved a password.
#
#  disabled
#    a user has been disabled because they have not verified their email
#
#  UPDATE: 11/29/2013
#    - a first user who signs up for a company through signup form will have state as 'pending_signup_completion' but will
#      move to 'active' once they set a password
#    - the second user for a company who signs up through signup form will have state 'pending_email_verification'
#
######################################################################################################################
require "set"

class User < ApplicationRecord

  has_paper_trail only: [:status]

  include Role::UserMethods
  include YammerUser
  include MicrosoftGraphUser
  include CacheKeyManager
  include UserAnalytics
  include Points::Calculator
  include UnsubscribeConcern
  include FbWorkplaceUserConcern
  include ActorConcern
  include CustomFieldMagic::UserConcern

  class Lite < Struct.new(:id, :email, :network, :label, :avatar_thumb_url)
    include HashIdConcern

    def self.model_name
      User.model_name
    end

    def first_name
    end

    def last_name
    end
  end
  acts_as_paranoid

  extend EmailBlacklist

  STATES = [:pending_signup_completion, :pending_email_verification, :invited, :invited_from_recognition, :pending_invite, :active, :disabled]
  PUBLIC_STATES = [:pending_signup_completion, :pending_email_verification, :invited, :invited_from_recognition, :pending_invite, :active]
  PENDING_STATES = [:pending_signup_completion, :pending_email_verification, :invited, :invited_from_recognition, :pending_invite]
  MINIMUM_PASSWORD_LENGTH = 14

  attr_accessor :original_password, :force_password_validation, :invitations, :skip_original_password_check, :password_strength_check
  attr_accessor :check_original_password_when_changing_email
  attr_accessor :external_source, :mugshot_url, :mugshot_url_template
  attr_accessor :created_by, :acting_as_superuser, :skip_name_validation, :skip_same_domain_check
  attr_accessor :enable_restricted_fields_check
  attr_accessor :new_record_temporary_id
  attr_accessor :bypass_disable_signups
  attr_accessor :has_changes_to_send_to_close
  attr_accessor :validate_terms_and_conditions
  attr_accessor :bypass_authlogic_persistence_token_validation

  serialize :has_read_features
  serialize :favorite_team_ids, Array

  belongs_to :company, counter_cache: :users_count, inverse_of: :users, optional: true
  belongs_to :invited_by, class_name: "User", foreign_key: "invited_by_id", counter_cache: :invited_users_count, optional: true
  belongs_to :manager, class_name: "User", optional: true

  has_many :employees, class_name: "User", foreign_key: "manager_id"
  has_many :user_company_roles
  has_many :user_permissions

  has_many :user_teams, dependent: :destroy
  has_many :authentications, inverse_of: :user, dependent: :destroy do
    def find(id_or_provider)
      if id_or_provider.to_i > 0
        where(id: id_or_provider)
      else
        where(provider: id_or_provider)
      end
    end

    def yammer
      select { |a| a.provider == "yammer" }.last
    end

    def google
      select { |a| a.provider == "google_oauth2" }.last
    end

    def google_oauth2
      google
    end

    def microsoft_graph
      select { |a| a.provider == "microsoft_graph" }.last
    end

  end

  has_many :user_roles, before_add: :ensure_directors_are_company_admins
  # has_many :roles, through: :user_roles # Role::UserMethods

  has_many :recognition_recipients, dependent: :destroy
  has_many :sent_nomination_votes, :class_name => "NominationVote", :foreign_key => "sender_id", dependent: :destroy
  has_many :received_nominations, class_name: "Nomination", as: :recipient, dependent: :destroy
  has_many :sent_recognitions, :class_name => "Recognition", :foreign_key => "sender_id", dependent: :destroy
  has_many :invited_users, :class_name => "User", :foreign_key => "invited_by_id"
  has_many :given_recognition_approvals, class_name: "RecognitionApproval", foreign_key: "giver_id", dependent: :destroy
  has_many :comments, foreign_key: "commenter_id", dependent: :destroy
  has_many :oauth_access_tokens, foreign_key: "resource_owner_id", class_name: "Doorkeeper::AccessToken"

  has_many :team_managers, foreign_key: "manager_id", dependent: :destroy

  has_many :documents_uploaded, class_name: "Document", foreign_key: :uploader_id, dependent: :destroy
  has_many :documents_requested, class_name: "Document", foreign_key: :requester_id, dependent: :destroy

  has_one :avatar, as: :owner, class_name: "AvatarAttachment", autosave: true
  has_one :email_setting, dependent: :destroy, inverse_of: :user, autosave: true, validate: true
  has_one :reminder, dependent: :destroy
  has_one :subscription
  has_one :user_stripe_customer

  has_many :point_activities, dependent: :destroy
  has_many :redemptions, dependent: :destroy, inverse_of: :user
  has_many :device_tokens
  has_many :managed_rewards, class_name: "Reward", foreign_key: "manager_id"
  has_many :webhook_endpoints, class_name: 'Webhook::Endpoint', foreign_key: "owner_id", dependent: :destroy

  has_many :likes, -> { where(name: "like").where("actor_id <> receiver_id") }, class_name: "ExternalActivity", foreign_key: "receiver_id" do
    def between(start_date: nil, end_date: nil)
      where("DATE(created_at) between DATE(?) and DATE(?)", start_date, end_date)
    end
  end

  has_many :task_submissions, foreign_key: :submitter_id, class_name: 'Tskz::TaskSubmission', dependent: :destroy
  has_many :completed_tasks, through: :task_submissions, class_name: 'Tskz::CompletedTask'
  has_many :teams, :through => :user_teams do
    def add(team)
      self.push(team) unless self.exists?(team.id)
    end

    def remove(team)
      self.delete(team) if self.exists?(team.id)
    end
  end
  has_many :direct_permissions, through: :user_permissions, source: "permission"
  has_many :company_roles, through: :user_company_roles do
    def add(role)
      self.push(role) unless self.exists?(role.id)
    end

    def remove(role)
      self.delete(role) if self.exists?(role.id)
    end
  end
  has_many :company_role_permissions, through: :company_roles
  has_many :proxy_permissions, through: :company_role_permissions, source: "permission"
  has_many :received_recognitions, through: :recognition_recipients, source: :recognition, dependent: :destroy
  has_many :received_badges, :through => :received_recognitions, :source => :badge
  has_many :sent_badges, :through => :sent_recognitions, :source => :badge

  delegate :sync_enabled?, :sync_provider, to: :company

  acts_as_authentic do |c|
    c.disable_perishable_token_maintenance = true
    # Constants::EMAIL_REGEX is deprecated in AuthLogic gem's latest version
    # c.validate_email_field = false
    # c.validate_password_field = false
    c.require_password_confirmation = false

    # https://github.com/binarylogic/authlogic/pull/526
    # c.maintain_sessions = false
    c.log_in_after_create = false
    c.log_in_after_password_change = true
    c.crypto_provider = ::Authlogic::CryptoProviders::SCrypt
  end

  validates :status, :slug, presence: true
  validates :email,
            format: {
              # these are deprecated in AuthLogic gem's latest version
              with: Constants::EMAIL_REGEX,
              scope: :deleted_at,
              message: Proc.new { I18n.t("activerecord.errors.models.user.attributes.email.invalid") },
              # this prevents duplicate error messages, as presence is being validate above
              allow_blank: true
            },
            uniqueness: { scope: [:deleted_at, :network], message: :email_uniqueness, case_sensitive: true },
            allow_nil: true

  validates :email, presence: true, unless: Proc.new{ |user| user.company_allows_phone_authentication? }

  validate :presence_of_email_or_phone_for_phone_enabled_companies

  validates :password, length: { minimum: User::MINIMUM_PASSWORD_LENGTH, if: :should_validate_password? }

  validates :first_name, :last_name, presence: true, if: :should_validate_name?
  validates :company, presence: true, if: Proc.new { |u| u.errors[:email].blank? }
  validates :network, presence: true, if: lambda { |u| u.company.present? }
  validates :slug, uniqueness: { scope: [:network, :deleted_at, :status], message: Proc.new { |a, b| "'#{b[:value]}' has been taken" }, case_sensitive: true}
  validates :employee_id, uniqueness: { scope: [:network], case_sensitive: true }, allow_nil: true
  validates :terms_and_conditions, acceptance: { accept: "true" }, if: :validate_terms_and_conditions

  validates_inclusion_of :locale, in: Proc.new { available_locale_info.keys }, message: Proc.new { |record, _| record.unsupported_locale_message}, allow_blank: true


  # validates :phone, format: {with: /\+1[02-9][\d]{9}/}, if: ->{ phone.present? }
  validates :phone, uniqueness: {scope: :network, case_sensitive: true}, allow_blank: true

  validate :status_is_valid
  validate :email_is_within_domain, on: :create
  validate :slug_contains_proper_characters, on: :update
  validate :changing_password_must_include_original_password
  validate :changing_email_must_include_original_password, if: :check_original_password_when_changing_email
  validate :has_no_password
  validates_strength_of :password, level: :strong, with: :email, using: StrongPasswordTester, if: :allow_password_strength_check?
  validate :network_in_company_family, unless: Proc.new { |u| u.personal_account? }
  validate :company_does_not_have_signups_restricted, on: :create
  # validate entities based onthe sync enabled on company settings
  validate :restricted_fields_changed, on: :update, if: :enable_restricted_fields_check
  validate :employee_id_is_immutable, on: :update
  validate :start_date_not_earlier_than_1900
  validate :email_not_blacklisted, on: :create

  validates_length_of :favorite_team_ids, maximum: 100, message: :favorite_limit_reached
  validates_inclusion_of :timezone, in: ActiveSupport::TimeZone.all.map(&:name), allow_nil: true

  before_validation :trim_email
  before_validation :ensure_company
  before_validation :ensure_network
  before_validation :ensure_status
  before_validation :ensure_slug, on: :create
  before_validation :nilify_blank_phone
  before_validation :format_phone
  before_validation :update_user_profile_settings, on: :create
  before_validation :massage_birthyear
  before_validation :nilify_blank_employee_id
  before_validation :nilify_blank_email
  before_validation :trim_employee_id
  before_save :ensure_unique_key
  before_validation :nilify_blank_timezone
  before_validation :convert_locale_to_short_code, if: -> { self.locale_changed? }

  before_create :build_email_settings
  after_create :add_default_user_role
  after_create :update_company_last_user_created_at
  after_create :handle_new_or_existing_domain_users
  after_create :bust_company_stats_cache
  after_update :handle_change_of_company

  ATTRIBUTES_TO_SEND_TO_CLOSE = ["phone", "job_title", "first_name", "last_name", "email"]
  after_create { self.has_changes_to_send_to_close = true }
  after_update {
    self.has_changes_to_send_to_close = true if (ATTRIBUTES_TO_SEND_TO_CLOSE & self.changes.keys).present?
  }

  after_commit :delayed_upsert_to_close


  accepts_nested_attributes_for :company, :email_setting

  scope :is_director, -> { joins(:user_roles).where(user_roles: { role_id: Role.director.id }) }
  scope :all_pending, -> { where(status: PENDING_STATES) }
  scope :pending_invite, -> { where(status: :pending_invite) }
  scope :not_disabled, -> { where("users.disabled_at is null and users.status <> 'disabled'") }
  scope :disabled, -> { where("users.disabled_at is NOT null OR users.status = 'disabled'") }
  scope :active, -> { where(status: 'active') } #excludes those who have been invited, only those who have logged in
  scope :invited_from_recognition, -> { where(status: 'invited_from_recognition') }
  # default_scope { joins(:user_roles).distinct }


  def grant(permission)
    direct_permissions << permission
  end

  def revoke(permission)
    direct_permissions.delete(permission)
  end

  def permissions
    (proxy_permissions + direct_permissions).uniq
  end

  def log_sync
    Rails.logger.info "Sync'd user: #{self.id}-#{self.email}"
    update_attribute(:synced_at, Time.now)
  end

  def consider_as_contact?
    return false if self.company.allow_admin_dashboard?
    first_user_ids = self.company.users.where("status not like '%invite%'").order("users.created_at asc").limit(3).pluck(:id)
    first_user_ids.include?(self.id)
  end

  def invited_by
    User.unscoped { super } #allows association to be deleted
  end

  def second_level_manager
    hierarchical_managers(depth: 2).second
  end

  def subscribed_account?
    # self.subscription.purchased? or self.company.subscription.purchased? rescue false
    self.company.allow_admin_dashboard? or self.company.subscription.try(:purchased?)
  end

  def find_or_build_subscription(plan, coupon, opts={})
    opts.merge!({ email: self.email })
    subscription = self.subscription || self.build_subscription.tap { |s| s.company_id = self.company_id }
    subscription.assign_attributes(opts)
    subscription.plan = plan
    return subscription
  end

  #might be time to put create_subscription! out to pasture
  def create_subscription!(plan, coupon, params)
    subscription = find_or_build_subscription(plan, coupon, params)
    subscription.save_with_payment!
    return subscription
  end

  def prime_caches!(update_points: true)
    Rails.logger.debug { "#{Time.now.to_formatted_s(:db)} - Priming caches for user(#{self.log_label})" }
    if self.auth_with_yammer?
      self.refresh_yammer_client!
      self.refresh_cached_user_graph!
      self.delay(queue: 'caching').refresh_cached_yammer_groups!
      self.refresh_cached_relevant_coworkers!
    end

    Rails.logger.debug { "#{Time.now.to_formatted_s(:db)} - Refreshing cached contacts" }
    self.update_all_points! if update_points
  rescue YammerClient::Unauthorized => e
    Recognize::Application.yammer_client.handle_unauthorized(e, self)
  end

  def self.admins
    User.active.joins(:user_roles).where(user_roles: {role_id: Role.admin.id}).distinct
  end

  def self.all_marketable_users
    set = self.joins(:email_setting).includes(:email_setting, :company => :subscription)
              .where(email_settings: { global_unsubscribe: false })
              .where(status: "active")
    return set
  end

  def self.all_unsubscribes
    set = self.joins(:email_setting).includes(:email_setting)
              .where(email_settings: { global_unsubscribe: true })
  end

  # users who do not have global unsubscribe checked
  def self.marketable_users(which: :unpaid, role: nil)
    set = self.joins(:email_setting).includes(:email_setting, :company => :subscription)
              .where(email_settings: { global_unsubscribe: false })
              .where(status: "active")

    if(which == :unpaid)
      set = set.select { |u|
        !u.company.allow_admin_dashboard? &&
        !u.company.subscription.try(:purchased?) &&
        !u.company.subscription.try(:canceled?) &&
        (role == :company_admin ? u.company_admin? : true)
      }
    elsif(which == :paid)
      set = set.select { |u|
        (u.company.allow_admin_dashboard? ||
        u.company.subscription.try(:purchased?)) &&
        !u.company.subscription.try(:canceled?) &&
        (role == :company_admin ? u.company_admin? : true)
      }
    end

    return set
  end

  def self.marketable_yammer_users(which: :unpaid, role: nil)
    marketable_users(which: which, role: role).select{|u| u.yammer_id.present? }
  end

  def self.newsletter_users
    set = self.marketable_users(which: :unpaid)
    set += self.marketable_users(which: :paid, role: :company_admin)
    return set
  end
  ###########################
  #
  # Ex.
  #   - User.export_mailing_list("tmp/recognize20160816-unpaid.csv", :marketable_users, {which: :unpaid})
  #   - User.export_mailing_list("tmp/recognize20160816-paid-admins.csv", :marketable_users, {which: :paid, role: :company_admin})
  #
  ###########################
  def self.export_mailing_list(filename, list_or_method_for_set, args)
    if list_or_method_for_set.kind_of?(Array)
      list = list_or_method_for_set
    else
      list = send(list_or_method_for_set, **args).map(&:email).join("\n")
    end

    File.open(filename, 'w'){|f| f.write(list) }
  end

  def self.find_or_create_by_oauth(oauth, opts = {})
    #user = User.find_or_create_by(email: oauth.email, created_by: :oauth)
    query = { email: oauth.email }
    if opts[:network].present?

      # Add support for looking user up by upn
      company = Company.from_domain(opts[:network])
      if company.settings.auth_via_user_principal_name?
        query = {user_principal_name: oauth.user_principal_name, network: opts[:network]}
      else
        query[:network] = opts[:network]
      end
    end


    user = User.with_deleted.where(query).first_or_initialize(created_by: :oauth)
    user.deleted_at = nil if user.deleted_at.present?
    user.apply_oauth(oauth)
    return user
  end

  def self.find_by_login(login, network = nil)
    # This method is used by authlogic to lookup user. Should be scoped to company.
    opts = if login =~ /.+@.+\..+/
      { email: login }
    else
      {
        phone: Twilio::PhoneNumber.format(login) || login,
        company_id: CompanySetting.where(allow_phone_authentication: true).select(:company_id)
      }
    end
    opts[:network] = network if network
    where(opts).first
  end

  def self.search_by_phone(phone, scope = self)
    formatted_phone = Twilio::PhoneNumber.format(phone) || phone
    companies_with_phone_auth = CompanySetting.where(allow_phone_authentication: true).select(:company_id)
    scope.where(phone: formatted_phone, company_id: companies_with_phone_auth)
  end

  def presence_of_email_or_phone_for_phone_enabled_companies
    return unless company_allows_phone_authentication?

    if email.blank? && phone.blank?
      errors.add(:email, 'or phone cannot be blank')
      errors.add(:phone, 'or email cannot be blank')
    end
  end

  def company_allows_phone_authentication?
    company.try(:settings).try(:allow_phone_authentication?)
  end

  def years_of_service
    return DateTime.now.year - self.start_date.year
  end

  def apply_oauth(oauth, build_authentications: true)
    if build_authentications
      auth = authentications.where(:provider => oauth.provider, :uid => oauth.uid).first_or_initialize
      auth.credentials = oauth.credentials
      auth.extra = oauth.extra
      self.authentications << auth
    end

    info = oauth.oauth.extra.raw_info

    self.email = oauth.email
    self.first_name = oauth.first_name if oauth.first_name.present?
    self.last_name = oauth.last_name if oauth.last_name.present?

    if oauth.yammer?
      if self.avatar.default? and !oauth.default_image?
        image_url_template = oauth.data.mugshot_url_template
        self.assign_yammer_avatar(image_url_template)
      end

      self.yammer_id = oauth.uid
      self.job_title = oauth.data.try(:job_title)

    elsif oauth.microsoft_graph?
      self.microsoft_graph_id = oauth.uid
      self.display_name = info.displayName
      self.user_principal_name = oauth.user_principal_name
      self.email = self.user_principal_name if self.company.try(:settings).try(:sync_email_with_upn?)

      User.delay(queue: 'priority_caching').sync_microsoft_graph_avatar(self.id) if self.id

    elsif oauth.google?
      begin
        self.avatar.remote_file_url = oauth.image
      rescue NoMethodError => e
        Rails.logger.warn("------")
        Rails.logger.warn("oauth image: #{oauth.image.inspect}")
        Rails.logger.warn(e.backtrace)
        Rails.logger.warn("------")
        raise e
      end
    end
  end

  def show_google_login?
    !self.authenticated_with_google? && self.company.allow_google_login? && !self.authenticated_with_yammer?
  end

  def can_view_hall_of_fame?
    company.allow_hall_of_fame? || HallOfFame.whitelist.include?(self.email)
  end

  def can_view_rewards?
    company.allow_rewards?
  end

  def can_view_comments?
    company.settings.allow_comments?
  end

  def can_post_private_recognitions?
    company.allows_private?
  end

  def authenticated_with_google?
    self.authentications.select { |a| a.provider == "google_oauth2" }.present?
  end

  def formatted_email
    # hack because with amazon SES requires senders to be verified
    "#{self.full_name.gsub(',','')} <donotreply@recognizeapp.com>"
  end

  def accepts_email?(setting=nil)
    return true if self.email_setting.blank?
    accepts = !self.email_setting.global_unsubscribe
    #setting can be nil so we can allow checking for global unsubscribe
    accepts &&= self.email_setting.send(setting) if self.email_setting.respond_to?(setting)
    return accepts
  end

  def first_user_for_company?
    if u = self.company.users.order("users.created_at asc, users.id asc").first
      u.id == self.id
    else
      false
    end
  end

  def has_read_feature?(feature)
    (has_read_features || {})[feature].present?
  end

  def has_read_feature!(feature)
    features = has_read_features || {}
    features[feature] = true
    update_attribute(:has_read_features, features)
  end

  def has_sendable_recognition_badges?
    self.sendable_recognition_badges.present?
  end

  def self.signup!(user_params)
    network = user_params.delete(:network) if user_params.respond_to?(:delete)
    user = User.new(user_params)
    user.skip_name_validation = true
    user.validate_terms_and_conditions = true
    if network
      user.network = network
      user.company = Company.from_domain(network) if network.present?
      user.skip_same_domain_check = true
    end
    user.save # this is weird that its not bang.

    return user
  end

  def update_profile(user_params)
    avatar_file = user_params.delete(:avatar)
    company_id = user_params.delete(:company_id)

    success = true
    success &&= update(user_params.to_h)

    if success and avatar_file
      success &&= update_avatar(file: avatar_file)
    end

    if success and company_id && company_id.to_i != self.company_id.to_i
      if self.company.family.map(&:id).include?(company_id.to_i) # allow moving within family only
        success &&= assign_company(company_id)
      end
    end

    SafeDelayer.delay(queue: 'caching').run(Company, self.company_id, :refresh_cached_users!)
    # self.company.delay(queue: 'caching').refresh_cached_users!

    return success
  end

  def assign_company(id)
    company = Company.find(id)
    return false unless company

    company.add_users!(self.id)
    return true #this smells
  end

  def update_avatar(file: )
    avatar_attachment = AvatarAttachment.new(file: file)
    self.avatar = avatar_attachment
    return self.avatar.save
    # return update_attribute(:avatar, avatar_attachment)
  rescue NoMethodError => e
    Rails.logger.warn("------")
    Rails.logger.warn(e.backtrace)
    Rails.logger.warn("------")
    FileUtils.cp(file.tempfile, (Rails.root+"log/"+file.original_filename).to_s)
    raise e
  rescue ImageAttachmentUploader::ImproperFileFormat => e
    self.errors.add(:base, e.message)
  rescue ActiveRecord::RecordNotSaved => e
    if avatar_attachment.errors
      avatar_attachment.errors.keys.each do |key|
        avatar_attachment.errors[key].each do |message|
          self.errors.add(:base, message)
        end
      end
    else
      self.errors.add(:base, "There was an error uploading.  Please try a different file.")
    end
    return false
  end

  def recognize!(recipients, badge, message, opts={})
    recipients = [recipients] unless recipients.kind_of?(Enumerable)
    unless badge.kind_of?(Badge)
      # The `badge` argument -- that is coming from API -- can be badge name or id. Use BadgeFinder to deduce badge.
      badge = BadgeFinder.find(self.company, badge) || self.company.default_badge
    end
    Recognition.create_custom(self, recipients, badge, message, opts)
  end

  def invite!(emails, recognition=nil, opts={})
    emails = [emails] unless emails.kind_of?(Array)
    new_users = []
    emails.each do |e|
      next if e.blank?
      e = e.index("@") ? e : "#{e}@#{self.company.domain}"
      opts[:bypass_disable_signups] = true unless opts.has_key?(:bypass_disable_signups)
      opts[:skip_same_domain_check] = true unless opts.has_key?(:skip_same_domain_check)
      opts[:company] = self.company
      new_users << add_user!(e, recognition, opts)
    end
    return new_users
  end

  def invite_from_recognition!(user, recognition, opts={})
    add_user!(user, recognition, opts)
  end

  def invite_user!(user)
    add_user!(user)
  end

  def resend_invite!(user, medium, verification_url)
    user.update_columns(invited_by_id: self.id, invited_at: Time.now)
    user.set_status!(:invited)
    if medium == :email
      UserNotifier.delay(queue: 'priority').invitation_email(user)
    else
      SmsNotifierJob.perform_now(user.id, sms_invitation_body(user.invited_by, verification_url))
    end
  end

  def sms_invitation_body(inviter, verification_url)
    "#{I18n.t("user_notifier.name_wants_you_to_join_recognize", name: inviter.full_name)}" +
    " #{I18n.t("user_notifier.verify_account_now")}. #{verification_url}"
  end

  def add_user_without_invite!(user, opts={})
    # NOTE: regarding bypass_authlogic_persistence_token_validation
    # This is wonky.
    # Reference: https://stackoverflow.com/questions/51318908/how-to-disable-session-maintenance-when-creating-a-user-with-authlogic?noredirect=1#comment89619060_51318908
    # https://github.com/binarylogic/authlogic/blob/6684439ff15ee1b10d8106675e9325e7e4aee87d/lib/authlogic/acts_as_authentic/persistence_token.rb#L25
    # https://github.com/binarylogic/authlogic/blob/master/lib/authlogic/acts_as_authentic/persistence_token.rb#L30
    # So, I've created a virtual attribute that will be used in an override method
    # in User#persistence_token_changed? which will turn off the validation if it returns false
    add_user!(user, nil, { skip_invitation: true,
                           skip_same_domain_check: true,
                           bypass_authlogic_persistence_token_validation: true,
                           bypass_disable_signups: true }.merge(opts))
  end

  # we don't want to use the deleted_at scope
  # company should always return for a user
  def company
    Company.unscoped { super }
  end

  def badge_counts(opts = {})
    opts = {order: :desc, limit: nil}.merge(opts)
    order = %i(asc desc).include?(opts[:order]) ? opts[:order].to_s.upcase: 'DESC'

    memoized_badge_counts_map_present = @badge_counts_map && @set_order == opts[:order] && @set_limit == opts[:limit]
    return @badge_counts_map if memoized_badge_counts_map_present

    @set_order = opts[:order]
    @set_limit = opts[:limit]

    @badge_counts_map = begin
      recognitions_received = self.received_recognitions.approved.group(:badge_id)
      recognitions_received = recognitions_received.limit(opts[:limit]) if opts[:limit] && opts[:limit].to_i > 0

      badge_id_and_count_map = recognitions_received.reorder("count_badge_id #{order}").count(:badge_id)
      badge_and_count_map = badge_id_and_count_map.map { |id, count| [Badge.cached(id), count] }
      badge_and_count_map
    end
  end

  def badge_counts_via_setting
    # reads company.settings.profile_badge_ids for which badges to include
    @badge_counts_map_via_setting ||= begin
      badge_ids = (self.company.settings.profile_badge_ids && self.company.settings.profile_badge_ids.reject(&:blank?).presence) || self.company.company_badges.recognitions.map(&:id)
      badge_counts_id_array = self.received_recognitions.approved.where(badge_id: badge_ids).group(:badge_id).count(:badge_id)
      badge_counts_array = badge_counts_id_array.map { |id, count| [Badge.cached(id), count] }
      badge_counts_map = Hash[badge_counts_array]
      badge_counts_map = badge_counts_map.sort{|badge_a, badge_b| badge_b[1] <=> badge_a[1]}
      badge_counts_map
    end
    return @badge_counts_map_via_setting
  end

  def avatar_thumb_url
    avatar.thumb.url
  end

  def avatar_small_thumb_url
    if mugshot_url_template.present?
      User.yammer_image_from_template(mugshot_url_template, { width: 100, height: 100 })
    else
      avatar.small_thumb.url
    end
  end

  # this method was derived from Badge#permalink
  def avatar_small_thumb_permalink
    # NOTE: action_controller.asset_host MUST be set to a fqdn, eg. http://localhost:3000/
    # url will have path to cdn image in production
    url = avatar_small_thumb_url
    if Rails.env.production?
      url = "https:" + [Recognize::Application.config.asset_host, "assets", url].join("/") if avatar.default?
    elsif Rails.env.test?
      url = url || ""
    else
      # development
      url = "https://" + [Rails.application.config.host, "assets", url].join("/") if avatar.default?
    end
    url
  end

  def label
    self.full_name
  end

  def type
    "User"
  end

  def log_label
    "#{self.id} - #{self.email}"
  end

  def as_json(options={})
    options[:only] ||= [:id, :first_name, :last_name, :email, :status, :job_title]
    options[:methods] ||= [:avatar_thumb_url, :label, :network_label, :type]

    super(options)
  end

  # useful for hiding "users" network
  def network_label
    network == "users" ? "" : network
  end

  def favorite_teams
    Team.where(id: favorite_team_ids, company_id: company_id)
  end

  def starred_team_ids
    (favorite_team_ids + user_team_ids).uniq
  end

  def user_team_ids
    user_teams.pluck(:team_id)
  end


  def update_favorite_teams(team_id, add)
    if team_id
      if (add == 'true')
        update_favorite_team_ids = favorite_team_ids + [team_id] unless favorite_team_ids.include?(team_id)
      else
        update_favorite_team_ids = favorite_team_ids - [team_id]
      end
      update(favorite_team_ids: update_favorite_team_ids)
    end
  end

  def company_permits_recognition?
    Subscription.feature_permitted?(self.company, self, :recognition)
  end

  def favorite_joined_teams
    @_favorite_joined_teams ||= (self.teams + self.favorite_teams).uniq { |t| t[:name] }.sort_by(&:name)
  end

  def domain_in_family?(network)
    company.family.map(&:domain).any? { |domain| domain.casecmp?(network) }
  end

  def last_non_disabled_status
    if self.versions.present?
      last_status = self.paper_trail.previous_version.status
      # This is for the case when the user has several sequential versions of being disabled,
      # which is not really needed right now as we only track the status attribute with paper_trail and
      # paper trail doesn't keep record of the object if the attribute/s doesn't change.
      if last_status == "disabled"
        # As of now PaperTrail doesn't have a method to query versions excluding a
        # particular set of values so had to resort to the following way.
        self.versions.reject { |x| x.reify.status == "disabled" }.last.reify.status
      else
        last_status
      end
    else
      self.login_count.positive? ? "active" : "pending_invite"
    end
  end

  protected

  def delayed_upsert_to_close
    opts = {has_changes_to_send_to_close: self.has_changes_to_send_to_close}
    SafeDelayer.delay(queue: 'sales').run(User, self.id, :upsert_to_close, opts) if self.has_changes_to_send_to_close
  end

  def upsert_to_close(opts = {})
    return unless consider_as_contact?
    return unless (self.has_changes_to_send_to_close || opts[:has_changes_to_send_to_close])

    close = Recognize::Application.closeio

    lead = close.find_lead_and_contact_for(self).first
    matching_lead_status = opts[:skip_lead_status_check] || (lead && lead.status_label&.match(/^Not/)) #Skip

    if (lead.blank? || matching_lead_status)

      fields = {}

      fields['status_id'] = 'stat_RAD34K1VHeyPLwtMiTCY4yzIircCeVI9QL1qtJ7ZP5U'
      fields['custom.lcf_o6mMctjRWIfJax9ZW6ywVLCCNSX0O0KMCMiMbVVIKoe'] = 'Sign up'
      fields['custom.lcf_SXrf66EfraLDDon46oPWC3wvaWMLrVrhTPwZJ6jPw2b'] = "https://recognizeapp.com/admin?network=#{self.company.domain}"

      Rails.logger.info "User#after_commit - about to upsert"
      lead_and_contact = close.upsert_contact(self.id, fields)

      ### assign sequence to lead
      close_settings = InternalSetting.close_settings

      payload = {
        'sequence_id': close_settings.close_sequence_id,

        'contact_id': lead_and_contact[1]['id'],
        'contact_email': lead_and_contact[1]['emails'][0]['email'],

        # Get sender_account_id from Close > Settings > Connected Accounts
        # And click on the connected account.
        # The id will be the end part of the url that begins with emailacct_
        # This account id must be associated with the production api key
        'sender_account_id': close_settings.close_sequence_sender_account_id,
        'sender_name': close_settings.close_sequence_sender_name,
        'sender_email': close_settings.close_sequence_sender_email
      }

      sequence_client = CloseioClient.client_for_sequence_subscriptions
      response = sequence_client.create_sequence_subscription(payload)
      Rails.logger.debug "Close sequence subscription for #{self.email} response: #{response}. Payload was: \n#{payload}"

    end
  end

  #this method allows manipulation of the user object just
  #after its creation, useful in the case of wanting to
  #set first and last name from Yammer
  # ALSO: this method used to be called #send_invitation!
  #       but that was too specific and invitations aren't even
  #       handled here, they're handled by UserObserver and
  #       switch on the user's status
  def add_user!(user_or_email_or_phone, recognition=nil, opts={}, &block)

    #allow stubs or full emails, but force company domain
    # email = email_stub.split("@")[0]+"@"+self.company.domain
    # return User.new() if User.exists?(email: email)
    u = begin
      if user_or_email_or_phone.kind_of?(User)
        user_or_email_or_phone
      else
        if user_or_email_or_phone.match(/\@/).present?
          User.new(email: user_or_email_or_phone)
        else
          self.company.users.build(phone: user_or_email_or_phone)
        end
      end
    end

    yield u if block_given?

    st = recognition.present? ?
        :invited_from_recognition :
        (opts[:skip_invitation] ? :pending_invite : :invited)

    u.company = opts[:company] if opts[:company].kind_of?(Company)
    u.skip_same_domain_check = true if opts[:skip_same_domain_check]
    u.bypass_disable_signups = opts[:bypass_disable_signups]
    u.bypass_authlogic_persistence_token_validation = opts[:bypass_authlogic_persistence_token_validation]
    u.set_status!(st)
    u.invited_at = Time.now
    u.invited_by = self
    u.skip_name_validation = true unless user_or_email_or_phone.kind_of?(User)
    # recognition.present? ? u.save : u.save!#(validate: false)
    u.invited_from_recognition? ?
      u.save! :
      (opts[:save_without_session_maintenance] ? u.save_without_session_maintenance : u.save)
    return u
  end

  public

  def email_to_slug
    email_slug = email.split("@")[0].gsub('.', '-').gsub(/[+']/, '-')
    email_slug += "1" if User.where(network: self.network, slug: email_slug).exists?
    self.string_contains_letter?(email_slug) ? email_slug : "user-#{email_slug}"
  end

  def generate_slug
    Thread.current.object_id.to_s(32)+Time.now.to_f.to_s.gsub('.', '').to_i.to_s(32)
  end

  def recognition_graph
    user_ids = Set.new

    recognitions.non_system.each do |recognition|
      user_ids.add(recognition.sender_id)
      recognition.recognition_recipients.each { |recipient| user_ids.add(recipient.user_id) }
    end

    users = User.not_disabled.where(id: user_ids.to_a).where("users.id <> #{id}")
    users.inject({}) { |h, u| h[u.email] = u; h }
  end

  def user_graph
   self.recognition_graph
  end

  def cached_user_graph
   if personal_account?
     recognition_graph = Rails.cache.fetch("user-#{self.id}-graph") do
       self.recognition_graph
     end
   else
     #company.cached_users.merge!(recognition_graph)
     company.cached_users
   end
 end

  def refresh_cached_user_graph!
    return if Rails.env.development?
    Rails.logger.debug("#{Time.now.to_formatted_s(:db)} - Refreshing cached user graph for user(#{self.log_label})")
    Rails.cache.write("user-#{self.id}-graph", self.user_graph)
  rescue TypeError => e
    ug = self.user_graph
    Rails.logger.warn("CACHE ERROR(user.rb#refresh_cached_user_graph): #{e}")
    Rails.logger.warn("#{ug.inspect}")
    return ug
  end

  def coworkers(term=nil, opts={})
    default_avatar_url = AvatarAttachmentUploader.new.default_url
    limit = (opts[:limit] || 100000000000).to_i
    matching_set = {}

    set = self.cached_user_graph || []
    set.delete(self.email) unless opts[:include_self]

    # 20181207 - Removed a lot of old code that had to do
    #            with backfilling results from "cached_contacts"
    #            which were contacts pulled in from Google contacts
    if term
      Profiler.step("search graph") {
        terms = term.split(/[\+\s]/).collect { |t| Regexp.quote(t) }
        set.each do |email, user|
          Profiler.step("search user: #{user.email}") {
            if user.matches_terms?(terms)
              matching_set[email] ||= user
            end
          }
          break if matching_set.length >= limit
        end
      }

    else
      matching_set = set

    end

    #HACK to make sure this user didn't end up in the set
    # set.delete(self.email)
    return matching_set.values
  end

  def matches_terms?(terms)

    result = true

    terms.each do |t|
      result &&= begin
        self.first_name.to_s =~ /#{t}/i or
          self.last_name.to_s =~ /#{t}/i or
          self.display_name.to_s =~ /#{t}/i
      end
    end
    return result
  end

  def self.attributes_for_json
    @@json_attributes ||= [:id, :email]
  end

  def self.system_user
    @@system_user ||= User.find_by_email("app@recognizeapp.com")
  end

  def sendable_badges
    # reject badges that have an explicit role, leaving ones that are non-restricted, basically
    # FIXME: this should be wrapped better by the library
    unrestricted_badges = self.company.company_badges.reject { |b| b.roles_with_permission(:send).present? }
    whitelisted_badges_by_role = Authz::Manager.new(self).find(:send, Badge)
    set = unrestricted_badges + whitelisted_badges_by_role
    set.reject(&:disabled?)
  end

  def completable_tasks(id_only: false)
    # Note: this is derived from the above method (sendable_badges)
    # reject tasks that have an explicit role that this user does not have

    permission = :send
    unrestricted_tasks = self.company.tasks.reject { |t| t.roles_with_permission(permission).present? }
    whitelisted_tasks_by_role = Authz::Manager.new(self).find(permission, Tskz::Task) || []
    set = unrestricted_tasks + whitelisted_tasks_by_role
    set = set.reject(&:disabled?)

    id_only ? set.map(&:id) : set
  end

  def redeemable_catalogs
    permission = :redeem
    unrestricted_catalogs = self.company.catalogs.reject { |catalog| catalog.roles_with_permission(permission).present? }
    whitelisted_catalogs_by_role = Authz::Manager.new(self).find(permission, Catalog)
    set = unrestricted_catalogs + whitelisted_catalogs_by_role
    set.select(&:is_enabled?)
  end

  def redeemable_rewards(opts = {})
    return self.company.rewards.enabled if self.company.catalogs.blank?

    catalog_ids = Array(opts[:catalog_ids])
    catalogs = redeemable_catalogs.select { |catalog| catalog_ids.include?(catalog.id) }
    catalogs.map(&:rewards).flatten.select(&:enabled?)
  end

  def sendable_nomination_badges
    sendable_badges.select(&:is_nomination?)
  end

  def sendable_recognition_badges
    sendable_badges.reject(&:is_nomination?)
  end

  def already_shared_sendable_recognition_badges
    sendable_badges.reject(&:is_nomination?).reject(&:requires_approval?)
  end

  def can_submit_tasks?
    tasks_enabled_for_company? && completable_tasks.size > 0
  end

  def tasks_enabled_for_company?
    company.settings.tasks_enabled?
  end

  def can_send_nominations?
    company.allow_nominations? && sendable_nomination_badges.size > 0
  end

  def create_team(team_params)
    team = self.company.teams.build(team_params)
    team.creator = self
    team.team_managers.build(manager: self)
    team.save

    begin
      # user could potentially be invalid sometimes
      # don't bork the team creation
      team.users << self
    rescue ActiveRecord::RecordInvalid => e
      ExceptionNotifier.notify_exception(e, {data: {user: self, also: "team creation succeeded, just didn't add creator to team because they are invalid somehow"}})
    end

    team
  end

  def add_team!(team_id)
    success = true

    if (self.teams.map(&:recognize_hashid).include?(team_id))
      return success
    end

    team = self.company.teams.find_from_recognize_hashid(team_id)

    self.teams << team
    success = (self.errors.count == 0)
    team.delay(queue: 'points').update_all_points! if success

    return success
  end

  def remove_team!(team_id)
    success = true

    unless (self.teams.map(&:recognize_hashid).include?(team_id))
      return success
    end

    team = self.company.teams.find_from_recognize_hashid(team_id)
    self.teams.delete(team)
    success = self.errors.count == 0

    team.delay(queue: 'points').update_all_points! if success
    return success
  end

  def verified?
    self.verified_at.present? or self.authentications.present?
  end

  def verify!(opts={})
    self.update_column(:verified_at, Time.now)

    #its possible that I could verify after I've completed signup(in the case of the first user)
    #so only update the status accordingly
    self.set_status!(:pending_signup_completion) unless self.active?

    return self
  end

  #use this method when a user has authenticated but you aren't sure
  #where in the flow they should be.  It lets them login and sets the
  #appropriate state so they are sent to the correct point in the signup flow
  def verify_and_activate!
    self.verify! unless self.verified?

    # hack to make sure people who come in via yammer get their verified_at column
    # set properly
    self.update_column(:verified_at, Time.now) if self.verified_at.blank?

    #this used to be in signups controller and password resets controller
    #but moving to here, because we use this method in more spots
    #and i made management of perishable token manual(instead of authlogic handling it)
    #so be safe and reset it whenever we verify
    self.reset_perishable_token!

    #activate if all the info is good
    self.set_status!(:active) if self.ok_to_login?
  end

  def set_status!(new_status)
    self.status = new_status

    if persisted?
      # An alternative and a better way to compliment the `update_column` method present here before,
      # would be using `self.paper_trail.update_column`. However, there seems to be a a bug with
      # the data it stores to the versions table. For detailed info see:
      # https://github.com/Recognize/recognize/pull/3763#issue-575612417
      self.save(validate: false)
    end
  end

  def friendly_status
    # TODO: abstract out the status to show a better status label
    #       for each internal status
    self.status.to_s.humanize
  end

  def avatar
    super or self.build_avatar
  end

  def deliver_password_reset_instructions!(medium, url = nil)
    if medium == :email
      UserNotifier.password_reset_instructions(self).deliver_now
    else
      SmsNotifierJob.perform_now(self.id, I18n.t("sms_notification.password_reset", url: url))
    end
  end

  def self.safe_full_name(email, first_name, last_name, display_name)
    if display_name.present?
      display_name
    elsif first_name.present?
      "#{first_name} #{last_name}"
    else
      email.split("@")[0].titleize.gsub('.', ' ') if email.present?
    end
  end

  def full_name
    return User.safe_full_name(self.email, self.first_name, self.last_name, self.display_name)
  end

  def recognitions
    Recognition.sent_or_received_by(self)
  end

  # Used by `declarative_authorization`.
  def role_symbols
    @role_symbols ||= roles.map &:name
  end

  def ok_to_login?
    persisted? and company.name.present? and verified? and (crypted_password.present? or authentications.present? or last_auth_with_saml_at.present?)
  end

  def is_on_team?(team_name)
    self.teams.any? { |t| t.name == team_name }
  end

  def interval_label
    Interval.new(self.company.reset_interval).noun
  end

  def destroy(deep_destroy: false)
    if deep_destroy
      super()
    else
      disable!
      notify_observers(:after_destroy)
    end
  end

  def activate!
    last_status = self.last_non_disabled_status
    self.set_status!(last_status)
    notify_observers(:after_activate!) if self.active?
    update_column(:disabled_at, nil)
  end

  def disable!(opts={})
    self.set_status!(:disabled)
    update_column(:disabled_at, Time.now)
  end

  def top_recognitions
    self.recognitions.approved.sort { |a, b| b.approvals_count <=> a.approvals_count }
  end

  def recognitions_sent_since(since)
    self.sent_recognitions.approved.where(Recognition.arel_table[:created_at].gt(since))
  end

  def recognitions_received_since(since)
    self.received_recognitions.where(Recognition.arel_table[:created_at].gt(since))
  end

  def personal_account?
    self.network == "users"
  end

  def company_name
    @company_name ||= self.company.name
  end

  #some meta-syntactic sugar to allow lookups by role name
  #eg User.first.admin?
  #this also caches the lookup in a class variable hash
  def method_missing(method_name, *args, &block)
    #creator method will return nil if we can't create the method
    proc = create_role_interrogator!(method_name)
    return proc.call if proc.respond_to?(:call)

    proc = create_state_interrogator!(method_name)
    return proc.call if proc.respond_to?(:call)

    super
  end

  def move_company_to!(new_company, opts={})
    old_company = self.company

    self.update_columns(company_id: new_company.id, network: new_company.domain)

    # need to disconnect user from old companies teams
    UserTeam.where(user_id: self.id).delete_all

    # also clean up team manager associations
    TeamManager.where(manager_id: self.id).delete_all

    # clean up company roles as they can't be taken with.
    UserCompanyRole.where(user_id: self.id).delete_all

    # DONT MOVE RECOGNITIONS
    # Recognitions should stay where they are earned b/c you can't move badges
    # As such, users keep their recognitions across companies in their profiles
    # as well as keeping their points. However, aggregate calculations on team and company
    # should not include disconnected recognitions

    # # clean up received recognitions that were part of team
    # RecognitionRecipient.where(recipient_id: self.id, team_id: old_company.teams.map(&:id)).delete_all

    # # clean up point activities that were part of team
    # PointActivity.where(user_id: self.id, team_id: old_company.teams.map(&:id)).delete_all

    # # update sent recognitions
    # Recognition.where(sender_id: self.id).update_all(sender_company_id: new_company.id)

    # # update received recognitions
    # RecognitionRecipient.where(recipient_id: self.id, team_id: nil).update_all(recipient_company_id: new_company.id, recipient_network: new_company.domain)

    # # update point activities
    # PointActivity.where(user_id: self.id, team_id: nil).update_all(company_id: new_company.id, network: new_company.domain)

    # # update users points
    # self.update_all_points!

    #update old company team points
    old_company.teams.map(&:update_all_points!)

    unless opts[:optimize_cache_refreshing]
      old_company.refresh_all_counter_caches!
      # old_company.delay(queue: 'caching').prime_caches!
      SafeDelayer.delay(queue: 'caching').run(Company, old_company.id, :prime_caches!)
    end
  end


  def can_send_achievements?
    # superceded by company roles
    true#company_admin? || team_managers.present?
  end


  def allow_invite?
    self.company.allow_invite?
  end

  def allow_teams?
    self.company.allow_teams?
  end

  def allow_stats?
    return false if self.company.hide_points?
    return self.company.allow_you_stats? || self.company.allow_top_employee_stats?
  end

  def allow_you_stats?
    self.company.allow_you_stats?
  end

  def allow_top_employee_stats?
    self.company.allow_top_employee_stats?
  end

  def set_manager(user_or_id)
    manager = user_or_id.kind_of?(User) ? user_or_id : User.where(company_id: self.company_id, id: user_or_id).first
    if manager
      update_column(:manager_id, manager.id)
    else
      # if user_or_id is user, it wont reach this portion of code
      # so considering only the id or nil scenario
      raise "ManagerNotFound: #{self.id} - #{user_or_id}"
    end
  end

  def clear_manager
    update_column(:manager_id, nil)
  end

  def is_sync_provider_microsoft?
    self.sync_provider == :microsoft_graph.to_s
  end

  def disable_for_microsoft_graph?
    self.sync_enabled? && is_sync_provider_microsoft?
  end

  def sync_phone_enabled?
    self.sync_enabled? && self.company.settings.sync_phone_data?
  end

  def sync_service_anniversary_data?
    self.sync_enabled? && self.company.settings.sync_service_anniversary_data?
  end

  def sync_display_name?
    self.sync_enabled? && self.company.settings.sync_display_name?
  end

  def sync_job_title?
    self.sync_enabled? && self.company.settings.sync_job_title?
  end

  def sync_department?
    self.sync_enabled? && self.company.settings.sync_department?
  end

  def sync_country?
    self.sync_enabled? && self.company.settings.sync_country?
  end

  def first_sso_login?
    self.last_auth_with_saml_at.blank?
  end

  def hierarchical_managers(depth: nil)
    hierarchical_managers_recursive(depth: depth)
  end

  # company default setting is respected unless the user has explictly set the value
  def timezone_with_company_default
    timezone || company_timezone
  end

  def company_timezone
    company&.settings&.timezone
  end

  def self.supported_locale_list
    available_locale_info.map { |short_code, humanized_form| "'#{short_code}' or '#{humanized_form}'" }.join(", ")
  end

  def unsupported_locale_message
    # Note: This is prepended by `Locale` implictly.
    "'#{self.locale}' is not one of the supported locales: #{User.supported_locale_list}"
  end

  protected

  def trim_email
    self.email = email.strip if self.email.present?
  end

  def nilify_blank_employee_id
    self.employee_id = nil if self.employee_id.blank?
  end

  def nilify_blank_email
    self.email = nil if self.email.blank?
  end

  def nilify_blank_phone
    self.phone = nil if self.phone.blank?
  end

  # nilify the timezone to respect company default setting
  # refer method 'timezone_with_company_default'
  def nilify_blank_timezone
    self.timezone = nil if self.timezone.blank?
  end

  def trim_employee_id
    self.employee_id = employee_id.strip if self.employee_id.present?
  end

  def email_not_blacklisted
    if User.blacklisted_email?(self.email) && !self.skip_same_domain_check
      self.errors.add(:email, I18n.t("sign_up.blacklisted_email_error"))
    end
  end

  #we validate the password when there is a company name AND the company name hasn't changed
  #which is the case right after we assign company name during signup
  #but also validate whenever changing the password
  #or when we're updating the password
  def should_validate_password?
    if self.crypted_password_changed?
      return true
    elsif self.force_password_validation
      return true
    else
      return false
    end
  end

  def should_validate_name?
    self.skip_name_validation.blank?
  end

  def ensure_slug
    if self.personal_account?
      self.slug = generate_slug
    else
      self.slug = generate_slug if self.phone.present?
      self.slug = self.email_to_slug if self.email.present?
    end
  end

  def format_phone
    return unless self.phone_changed?

    self.phone = nil if self.phone.blank?

    if self.phone.present? && !sync_phone_enabled?
      # Twilio::PhoneNumber#format will return nil if number is invalid.
      formatted_number = Twilio::PhoneNumber.format(self.phone)
      if formatted_number
        self.phone = formatted_number
      else
        # NOTE: removing validation errors on invalid phone.
        #       who cares? its up to the user to put the correct phone number
        #       Can always improve by sending specific error in case of user
        #       manually inputting phone via user profile
        # self.errors.add(:phone, "is invalid")
      end
    end
  end

  BIRTHYEAR = 1908
  def massage_birthyear
    if birthday && birthday.year != BIRTHYEAR
      self.birthday = birthday.change(year: BIRTHYEAR)
    end
  end

  def ensure_status
    if self.status.blank?
      self.status = :pending_signup_completion
    elsif !status.kind_of?(Symbol)
      self.status = status.to_sym
    end
  end

  def ensure_company
    if self.company.blank? and self.email.present?
      if self.personal_account?
        company = Company.find_by_domain("users")
      else
        company = Company.from_email(self.email) if self.email.match(Constants::EMAIL_REGEX)
      end
      self.company = company
    end
  end

  def ensure_network
    if self.company.present? and self.network.blank? and !self.personal_account?
      self.network = self.company.domain
    end
  end

  def ensure_directors_are_company_admins(user_role)
    if user_role.role == Role.director && !self.roles.include?(Role.company_admin)
      self.roles << Role.company_admin
    end
  end

  def add_default_user_role
    self.roles << Role.employee
  end

  def create_role_interrogator!(m)
    method_name = m.to_s
    if match = method_name.match(/(.*)\?$/)
      role = Role.send(match[1]) rescue nil
      if role
        Rails.logger.debug "defining User.instance.#{method_name}"

        self.class.send(:define_method, method_name) do
          # self.roles.include?(Role.send(match[1]))
          self.user_roles.any? { |r| r.role_id == Role.send(match[1]).id }
        end

        return method(method_name)
      end
    end

  end

  def create_state_interrogator!(m)
    method_name = m.to_s
    if match = method_name.match(/(.*)\?$/) and STATES.include?(match[1].to_sym)
      Rails.logger.debug "defining User.instance.#{method_name}"

      self.class.send(:define_method, method_name) do
        self.status.to_s == match[1]
      end
      return method(method_name)
    end

  end

  def email_contains_a_letter
    prefix = (self.email and self.email.split("@")[0])
    if prefix and !self.string_contains_letter?(prefix)
      errors.add(:email, I18n.t('activerecord.errors.models.user.prefix'))
    end
  end

  def slug_contains_proper_characters
    if slug.present? and !self.string_contains_letter?(slug)
      errors.add(:slug, I18n.t("activerecord.errors.models.user.one_letter"))
    elsif slug.present? and !slug.match(/^[a-zA-z0-9\-_\+]+$/)
      errors.add(:slug, I18n.t("activerecord.errors.models.user.slug_format"))
    end
  end

  def string_contains_letter?(str)
    str.match(/[a-zA-Z]+/)
  end

  def email_is_within_domain
    if self.company && self.email_changed? && !self.personal_account? && !skip_same_domain_check
      new_domain = self.email.split("@")[1]

      if new_domain
        if self.company.persisted?
          new_domain_in_company_set = self.company.domains.map(&:domain).map(&:downcase).include?(new_domain.downcase)
          errors.add(:email, I18n.t("activerecord.errors.models.user.email_domain")) unless new_domain_in_company_set

        # the case where a company doesn't exist but I'm trying to save a user first
        # happens in tests, and may or may not happen in real life
        # In this case, the domains relationship on company hasn't been created yet
        # so just check against the core company domain
        elsif new_domain.downcase != self.company.domain.downcase
          errors.add(:email, I18n.t("activerecord.errors.models.user.email_domain"))
        end
      end
    end
  end

  def handle_new_or_existing_domain_users
    if skip_same_domain_check || Company.has_other_users_in_domain?(self)
      self.set_status!(:pending_email_verification) unless self.pending_invite? || self.invited? || self.invited_from_recognition?
    else
      self.roles << Role.company_admin
      self.company.teams.each { |t| t.creator = self; t.save! }

      unless (self.invited? and self.invited_by.company_id == self.company_id) or self.invited_from_recognition?
        #this will get fired when we're creating the system user, so prevent it from sending itself this recognition
        #which if happens will cause an error in creating the system user and fugh everything else up
        # NOTE: the check must as specified as opposed to self.system_user?, I'm not sure why...
        recognition = User.system_user.recognize!(self, Badge.ambassador, "For showing leadership in starting recognition.") unless User.system_user == self
      end
    end
  end

  def bust_company_stats_cache
    Report::CacheManager::Company.delay(queue: 'priority_caching').bust_and_reprime_report_caches!(self.company_id)
  end

  def handle_change_of_company
    if company_id_changed? and company_id_change[0].present?
      self.sent_recognitions.update_all("sender_company_id = #{company_id_change[1]}")
    end
  end

  def changing_password_must_include_original_password
    if password_changed? and crypted_password_was.present? and !skip_original_password_check
      errors.add(:original_password, "must be included to change your password") if original_password.blank?
      errors.add(:original_password, "does not match your original password") if original_password.present? and !valid_password?(original_password)
    end
  end

  # This validation is applicable for the user edit page only (not invoked in company admin)
  def changing_email_must_include_original_password
    if email_changed? and crypted_password_was.present?
      if original_password.blank?
        errors.add(:original_password, "must be included to change your email")
      elsif !valid_password?(original_password)
        errors.add(:original_password, "does not match your original password")
      end
    end
  end

  def has_no_password
    if self.company && self.company.disable_passwords? && (self.password.present? || self.original_password.present?)
      errors.add(:base, "Password can not be set due to company policy.")
    end
  end

  # check if the assigned network matches the domains
  # of the company's family(as specified via company id)
  def network_in_company_family
    if self.company && !self.domain_in_family?(self.network)
      #FIXME: UPDATE TRANSLATION
      errors.add(:network, I18n.t('activerecord.errors.models.bulk_user_updater.all_users_are_valid', default: 'is not a valid department.'))
    end
  end

  def company_does_not_have_signups_restricted
    if self.company && self.company.disable_signups? && !self.bypass_disable_signups
      errors.add(:base, I18n.t("activerecord.errors.models.company.signup_restricted"))
    end
  end

  def ensure_unique_key
    uniqueness_attribute = (company_allows_phone_authentication? && self.email.blank?) ? :phone : :email
    self.unique_key = "#{self.send(uniqueness_attribute)}-#{self.network}"
  end

  def build_email_settings
    self.build_email_setting
  end

  def should_validate_user_attrs
    # we check the "skip_original_password_check" here which is to
    # skip validations except password when we're resetting the password
    self.active? and !self.skip_original_password_check
  end

  def update_company_last_user_created_at
    # Only update `last_user_created_at` for users other than the first user
    #  as `last_user_created_at` is an indicator for users that are added later.
    self.company.update_attribute(:last_user_created_at, Time.current) if self.company.users_count > 1
  end

  # default value from company settings
  def update_user_profile_settings
    if self.company.try(:settings)
      settings = self.company.settings
      self.assign_attributes(locale: settings.default_locale, receive_birthday_recognitions_privately: settings.default_birthday_recognition_privacy, receive_anniversary_recognitions_privately: settings.default_anniversary_recognition_privacy )
    end
  end

  def restrict_avatar_access
    self.company.restrict_avatar_access?
  end

  # make sure the restricted fields are not changed
  # call to this method is conditional
  def restricted_fields_changed
    restricted_fields = []

    if self.sync_enabled?
      restricted_fields += %w(first_name last_name email)
      restricted_fields << :phone if sync_phone_enabled?
      restricted_fields << :job_title if sync_job_title?

      if self.is_sync_provider_microsoft?
        restricted_fields += %w(birthday start_date) if sync_service_anniversary_data?
        restricted_fields << :display_name if sync_display_name?
        restricted_fields << :department if sync_department?
        restricted_fields << :country if sync_country?
      end
    end

    restricted_fields.uniq.each do |field|
      if self.send("#{field}_changed?")
        errors.add(field.to_sym, "can not be modified")
      end
    end
  end

  def employee_id_is_immutable
    return unless employee_id_changed?
    return if employee_id_was.nil?
    errors.add(:employee_id, "Id can not be modified once set")
  end

  def start_date_not_earlier_than_1900
    if self.start_date.present? && self.start_date.year < 1900
      errors.add(:start_date, "must not be earlier than 1900")
    end
  end

  def self.users_by_status_for_company(company_id)
    User.where(company_id: company_id).where.not(status: nil).group(:status).count(:status)
  end

  def allow_password_strength_check?
    return false if password.blank?
    password_strength_check
  end

  private
  #
  # Returns an array of hierarchical managers for a user.
  # +depth+ :
  #       - if provided, traverse upto the depth.
  #       - if not provided, traverse upto possible depth.
  # +hierarchical_manager_ids+ :
  #         - it is exclusively used by the recursion and should not be passed in when calling from outside.
  # Note: The following conditions terminate the recursion.
  #       - can_not_go_deeper(depth is reached or the current user (in scope) doesn't have manager)
  #       - user_is_her_own_manager
  #       - cyclic_hierarchy_detected
  #
  # This method is not part of the public api and should instead be accessed via `hierarchical_managers`
  def hierarchical_managers_recursive(depth: nil, hierarchical_manager_ids: [])
    can_not_go_deeper = self.manager.blank? || (depth && depth <= 0)
    user_is_her_own_manager = self.id == self.manager&.id
    cyclic_hierarchy_detected = hierarchical_manager_ids.include?(self.manager&.id)

    base_case_of_recursion =  can_not_go_deeper || user_is_her_own_manager || cyclic_hierarchy_detected
    return [] if base_case_of_recursion

    new_depth = depth ? depth - 1 : depth # preseve the nil depth
    hierarchical_manager_ids << manager.id
    return (
    [manager] +
      manager.send(:hierarchical_managers_recursive, depth: new_depth, hierarchical_manager_ids: hierarchical_manager_ids)
    ).reject{ |u| u == self }
  end

  def status_is_valid
    self.status.present? && STATES.include?(self.status.to_sym)
  end

  def convert_locale_to_short_code
    return if self.locale.in? User.available_locale_info.keys

    locale_short_code = User.available_locale_info.key(self.locale)
    # Only convert if there is a valid conversion, else leave as is and let the relevant inclusion validation kick in.
    self.locale = locale_short_code if locale_short_code.present?
  end

  def self.human_attribute_name(attribute, options = {})
    attribute == :employee_id ? 'Employee Id' : super
  end

  def self.available_locale_info
    CompanySetting.available_locale_info
  end

  #very private method, only meant to be used in seeds and tests
  #but i'm putting here so its all in one place
  def self._create_system_user!
    unless User.exists?(User.system_user.try(:id))
      system_user = User.new(first_name: "Recognize", last_name: "Team", email: "app@recognizeapp.com")
      #hack to fix tests
      #for some reason, there is weird excon error...
      unless Rails.env.test?
        f = File.open(Rails.root.join("app/assets/images/chrome/logo_180x180.png"))
        system_user.avatar.file = f
      end
      system_user.send(:ensure_company)
      system_user.send(:ensure_network)
      system_user.send(:ensure_slug)
      system_user.set_status!(:disabled)
      system_user.disabled_at = Time.now
      system_user.save(validate: false)
      system_user.company.send(:initialize_point_values)
      system_user.company.send(:initialize_company_domains)
      system_user.company.save
      system_user.user_roles.delete_all
      system_user.roles = [Role.system_user]
      system_user.company.update_attribute(:name, "Recognize App")
    end
  end

  def self.custom_field_attributes
    columns.select { |column| column.name.start_with? "custom_field" }.map(&:name)
  end

  # this is used only for debugging
  def sessions
    @@session_set ||= ActiveRecord::SessionStore::Session.all.select { |s| s.data.has_key?("user_credentials_id") }
    @@session_set.select { |s| s.data["user_credentials_id"] == self.id }
  end

  # If this is raised, see UserSync::Base#create_recognize_user
  # Because we need to bypass authlogic's persistence_token
  # uniqueness validation

  # A TODO due to limited domain knowledge
  # raise "DoubleCheckAuthLogicPersistenceTokenChangedMethod" unless Rails.version == "5.0.7.2"

  def persistence_token_changed?
    bypass_authlogic_persistence_token_validation ? false : super
  end
end
