class Company < ApplicationRecord
  include YammerCompany
  include MicrosoftGraphCompany
  include FbWorkplaceCompanyConcern
  include CompanyAnalytics
  include CacheKeyManager
  include CompanyPointsConcern
  include Wisper::Publisher
  include SamlConcern
  include TldConcern
  include CustomFieldMagic::CompanyConcern
  include CustomLabelsConcern

  acts_as_paranoid
  mount_uploader :last_accounts_spreadsheet_import_file, AccountsSpreadsheetUploader
  # TODO: Is this needed for migration to run successfully?
  mount_uploader :last_accounts_spreadsheet_import_problematic_records_file, AccountsSpreadsheetUploader

  BETA_DOMAINS = ["wested.org", /recognizeapp[0-9]*\.com/]

  SETTINGS = [
      :allow_posting_to_yammer_wall,
      :allow_google_login,
      :allow_google_contact_import,
      :allow_daily_emails,
      :allow_instant_recognition,
      :allow_hall_of_fame,
      :reset_interval,
      :allow_yammer_manager_recognition_notification,
      :message_is_required,
      :recognition_limit_frequency,
      :recognition_limit_interval_id,
      :recognition_limit_scope_id,
      :default_recognition_limit_frequency,
      :default_recognition_limit_interval_id,
      :default_recognition_limit_scope_id,
      :global_privacy,
      :allow_yammer_connect,
      :allow_invite,
      :allow_teams,
      :allow_you_stats,
      :allow_top_employee_stats,
      :disable_passwords,
      :allow_rewards,
      :require_approval_for_provider_reward_redemptions,
      :disable_signups,
      :allow_recognition_sms_notifications,
      :allow_nominations,
      :nomination_message_is_required,
      :sync_enabled,
      :sync_teams,
      :allow_microsoft_graph_oauth,
      :enable_yammer_stats,
      :limit_sending_to_intracompany_only,
      :sync_provider,
      :private_user_profiles,
      :hide_points,
      :restrict_avatar_access,
      :show_recognition_tags,
      :nomination_global_award_limit_interval_id,
      :allow_quick_nominations,
      :allows_private,
      :currency,
      :allow_admin_report_mailer,
      :allow_manager_report_mailer,
      :program_enabled,
      :recognition_wysiwyg_editor_enabled,
      :post_to_yammer_group_id
  ]

  belongs_to :parent_company, class_name: "Company", optional: true
  has_one :saml_configuration, dependent: :destroy
  has_one :subscription, dependent: :destroy
  has_one :customizations, dependent: :destroy, class_name: "CompanyCustomization"
  has_one :settings, dependent: :destroy, class_name: "CompanySetting"
  has_many :ms_teams_configs, dependent: :destroy
  has_many :child_companies, class_name: "Company", foreign_key: "parent_company_id"
  has_many :teams, dependent: :destroy
  has_many :users, dependent: :destroy, inverse_of: :company
  has_many :active_users, -> { where({disabled_at: nil}, includes: :avatar) }, dependent: :destroy, inverse_of: :company, class_name: "User"
  has_many :sent_recognitions, class_name: "Recognition", foreign_key: "sender_company_id"
  has_many :recognition_recipients, foreign_key: "recipient_company_id", dependent: :destroy
  has_many :received_recognitions, through: :recognition_recipients, class_name: "Recognition", source: :recognition, dependent: :destroy
  has_many :badges
  has_many :line_items, inverse_of: :company, dependent: :destroy
  has_many :rewards
  has_many :reward_variants, through: :rewards, source: :variants do
    def company_fulfilled
      where('rewards.provider_reward_id is NULL')
    end
  end
  has_many :redemptions, dependent: :destroy, inverse_of: :company
  has_many :company_roles
  has_many :campaigns, dependent: :destroy, inverse_of: :company
  has_many :domains, dependent: :destroy, inverse_of: :company, class_name: "CompanyDomain"
  has_many :funds_accounts, dependent: :destroy, class_name: "Rewards::FundsAccount"

  has_many :task_submissions, dependent: :destroy, class_name: 'Tskz::TaskSubmission'
  has_many :tasks, inverse_of: :company, dependent: :destroy, class_name: 'Tskz::Task'
  has_many :completed_tasks, inverse_of: :company, dependent: :destroy, class_name: 'Tskz::CompletedTask'
  has_many :tags, inverse_of: :company, dependent: :destroy
  has_many :catalogs, inverse_of: :company, dependent: :destroy
  has_many :documents, inverse_of: :company, dependent: :destroy
  has_many :invoice_documents, inverse_of: :company, dependent: :destroy
  has_many :daily_stats, class_name: "DailyCompanyStat", inverse_of: :company, dependent: :destroy
  has_many :webhook_endpoints, class_name: 'Webhook::Endpoint', dependent: :destroy
  has_many :webhook_events, class_name: 'Webhook::Event', dependent: :destroy

  scope :admin_dashboard_enabled, ->{ where(allow_admin_dashboard: true) }
  scope :program_enabled, ->{ where(allow_admin_dashboard: true, program_enabled: true) }
  scope :with_specific_timezone, -> (timezone) { includes(:settings).where(company_settings: { timezone: timezone }) }

  serialize :anniversary_notifieds, Hash
  serialize :birthday_notifieds, Hash

  serialize :labels, Hash

  before_validation :set_default_company_name
  before_validation :set_new_company_secure_defaults, on: :create
  before_validation :initialize_company_domains, on: :create

  validates :name, presence: true, on: :update, unless: Proc.new { |c| c.domain == "users" }
  validates :domain, presence: true, if: :has_parent_company?
  validates :domain, uniqueness: { scope: :deleted_at, case_sensitive: true }
  validates :currency, presence: true, :inclusion => { :in => Rewards::Currency.supported_currencies_iso_codes }
  validates :sync_provider, presence: true, inclusion: { in: UserSync.providers.map(&:to_s) }
  validates :price_package, inclusion: { in: Subscription.valid_price_package_values }
  validate :kiosk_mode_key_contains_proper_characters, on: :update
  validate :verify_badges_when_disallowing_private_recognitions, on: :update

  before_destroy :check_subcompany_has_no_users, if: Proc.new { |c| c.parent_company_id.present? }
  after_create :create_default_teams
  after_update :run_settings_callbacks

  after_commit on: :create do
    publish(:company_created, self)
  end

  def allow_manager_of_manager_notifications?
    settings.allow_manager_of_manager_notifications?
  end

  def primary_funding_account
    # TODO: support funding accounts for currencies other than USD
    funds_accounts.primary.first || funds_accounts.primary.build(currency_code: 'USD')
  end

  def nomination_global_award_limit_interval
    Interval.new(nomination_global_award_limit_interval_id)
  end

  # user_badge_nominated_map[user][badge] = date
  # user_badge_nominated_map[100][200] = 12/1/2015
  def user_badge_nomination_awarded_map
    @user_badge_nomination_awarded_map ||= begin

      awarded_nominations = Nomination
        .includes(:campaign)
        .references(:campaign)
        .where(nominations: {is_awarded: true, recipient_type: "User"})
        .where(campaigns: {company_id: self.id})

      awarded_nominations.inject({}) do |hash, nomination|
        hash[nomination.recipient_id] ||= {}
        hash[nomination.recipient_id][nomination.campaign.badge_id] = nomination.awarded_at
        hash
      end
    end
  end

  def user_last_awarded_badge_at(user, badge)
    user_badge_nomination_awarded_map[user.id][badge.id] rescue nil
  end

  def uses_employee_id?
    @uses_employee_id ||= self.users.where.not(employee_id: nil).exists?
  end

  # NOTE: so here's the rationale behind this method:
  #       we override User#destroy such that all user destroys are really disables
  #       unless you call User#destroy(deep_destroy: true)
  #       So, without overriding this method, when you call Company#destroy
  #       it merely disables all its users but that's not what we want
  #       If we're destroying a company, we also want to deep destroy users
  #       So rather than get in the hairy business of tracking associations
  #       simply call super, and then do the hard delete of users when its complete
  def destroy
    super()
    self.users.map { |u| u.destroy(deep_destroy: true) }
    return nil
  end

  def recognizeapp?
    domain == "recognizeapp.com"
  end

  # hack to not release this feature to everyone until its tested more thoroughly
  def allow_send_limit_scope_selection?
    #["recognizeapp.com", "seegrid.com"].include?(self.domain)
    false
  end

  def recognition_limit_scope
    Recognition::LimitScope.find(recognition_limit_scope_id || Recognition::LimitScope::SCOPE_LIMIT_BY_USERS)
  end

  def default_recognition_limit_scope
    Recognition::LimitScope.find(default_recognition_limit_scope_id || Recognition::LimitScope::SCOPE_LIMIT_BY_USERS)
  end

  # badge that will be chosen for a recognition
  # when none is specified
  def default_badge
    self.company_badges.first
  end

  def name
    if domain == "chempoint.com"
      return "ChemPoint"
    else
      super
    end
  end

  def user_team_map
    UserTeam
      .joins(:team, user: :company)
      .includes(:team, user: :company)
      .where(companies: {id: self.id}).inject({}) do |hash, ut|
        hash[ut.user.email] ||= ut.team.name
        hash
      end
  end

  def team_to_member_count_map
    UserTeam
      .joins(:team, :user)
      .where(teams: {company_id: self.id}, users: {disabled_at: nil})
      .group(:team_id).count(:team_id)
  end

  # Returns a hash in `{<manager_id>: <direct reports count>}` format
  def user_direct_report_count_map
    self.users.not_disabled.where.not(manager_id: nil).group(:manager_id).count
  end

  def add_director!(email)
    user = self.users.find_by_email(email)
    if user.director?
      raise "User is already director"
    else
      user.roles << Role.director
    end
    return user
  end

  def remove_director!(id)
    user = self.users.find(id)
    UserRole.where(user_id: user.id, role_id: Role.director.id).delete_all
    return user
  end

  def anniversary_notifieds
    an = attributes["anniversary_notifieds"]
    an.present? ? an : { company_role_ids: [], role_ids: [], user_ids: [], team_ids: [] }
  end

  def birthday_notifieds
    bn = attributes["birthday_notifieds"]
    bn.present? ? bn : { company_role_ids: [], role_ids: [], user_ids: [], team_ids: [] }
  end

  # TODO: Handle cases where there might not be a single notified. Eg: All company admins opted out of the relevant notfication email.
  def sync_report_notifieds
    custom_user_ids = self.settings.user_ids_to_notify_of_sync_report
    custom_user_ids.present? ? User.find(custom_user_ids) : self.company_admins
  end

  def nominations_enabled?(user)
    allow_nominations? && user.sendable_nomination_badges.size > 0
  end

  def tasks_enabled?(user)
    self.settings.tasks_enabled? && user.completable_tasks.size > 0
  end

  def recognition_tags_enabled?
    self.show_recognition_tags? && self.tags.recognition_taggable.size > 0
  end

  def allow_manager_to_resolve_recognition_she_sent?
    self.settings.allow_manager_to_resolve_recognition_she_sent?
  end

  # FIXME: I am a Stub.
  # It is a bit tricky to determine when to show `tag` column in the relevant datatable. An example:
  # Say a company has `show_recognition_tags` turned off, but the company has recognitions (from the past) that have
  # tags attached to them.
  def include_tag_column_in_recognition_datatable?
    true
  end

  def company_badges
    self.custom_badges_enabled? ?
        self.badges.enabled :
        (self.created_at < Time.parse("2014-02-23") ? Badge.all_user_badges : Badge.user_badges)
  end

  def anniversary_badges
    self.badges.anniversary
  end

  def directors
    users.is_director
  end

  def label
    "#{self.name} (#{self.domain})"
  end

  def company_role_is_notified_of_birthday?(company_role)
    self.birthday_notifieds[:company_role_ids] &&
        self.birthday_notifieds[:company_role_ids].include?(company_role.id)
  end

  def role_is_notified_of_birthday?(role)
    self.birthday_notifieds[:role_ids].include?(role.id)
  end

  def team_is_notified_of_birthday?(team)
    self.birthday_notifieds[:team_ids].include?(team.id)
  end

  def company_role_is_notified_of_anniversary?(company_role)
    self.anniversary_notifieds[:company_role_ids] &&
        self.anniversary_notifieds[:company_role_ids].include?(company_role.id)
  end

  def role_is_notified_of_anniversary?(role)
    self.anniversary_notifieds[:role_ids].include?(role.id)
  end

  def team_is_notified_of_anniversary?(team)
    self.anniversary_notifieds[:team_ids].include?(team.id)
  end

  # DEPRECATING - 6/24/2016
  # def all_teams_notified_of_anniversary?
  #   all_teams_notified = true
  #   self.teams.each do |team|
  #     if (!(team_is_notified_of_anniversary?(team)))
  #       all_teams_notified = false
  #     end
  #   end
  #   return all_teams_notified
  # end

  # if opts[:optimize_cache_refreshing], then we can optimize
  # the busting of the cache, only bust cache on old and new companies once
  # Passing this flag makes the assumption that all users in the set are coming from the same company
  def add_users!(user_ids, opts={})
    set = User.where(id: user_ids)

    if opts[:optimize_cache_refreshing]
      old_company = set[0].company
    end

    set.each do |u|
      old_company ||= u.company
      Rails.logger.debug { "Moving user(#{u.log_label}) from (#{old_company.domain}) to (#{self.domain})" }
      u.move_company_to!(self, opts)
    end

    if opts[:optimize_cache_refreshing]
      Rails.logger.debug { "Priming COUNTER and COMPANY caches for #{old_company.domain}" }
      old_company.refresh_all_counter_caches!
      # old_company.delay(queue: 'caching').prime_caches!
      SafeDelayer.delay(queue: 'caching').run(Company, old_company.id, :prime_caches!)
    end

    Rails.logger.debug { "Priming COUNTER and COMPANY caches for #{self.domain}" }
    self.refresh_all_counter_caches!
    # self.delay(queue: 'caching').prime_caches!
    SafeDelayer.delay(queue: 'caching').run(Company, self.id, :prime_caches!)
  end
  # return all parents and sibling if any
  def family
    return [self] unless in_family?

    if child_companies.present?
      set = [self] + child_companies
    else
      set = [self.parent_company] + self.parent_company.child_companies
    end
    return set
  end

  def in_family?
    child_companies.present? or has_parent_company?
  end

  def make_child_company!(name)
    company = self.dup
    company.parent_company = self
    company.name = name
    company.has_theme = false
    url_reserved_keywords_regex = Regexp.new("[" + Addressable::URI::CharacterClasses::RESERVED + "]")
    name = name.gsub(url_reserved_keywords_regex, '').strip.gsub(/ +/, '-')
    company.domain = (self.domain+"-" + name).downcase
    company.slug = company.domain

    attributes_uninheritable_by_child_company.each do |attribute|
      company.assign_attributes(attribute => nil)
    end

    company.save

    if company.errors.blank?
      company.delay(queue: 'priority').enable_custom_badges! if self.custom_badges_enabled?
      company.refresh_all_counter_caches!
    end
    company
  end

  def has_parent_company?
    self.parent_company_id.present?
  end

  def child_company?
    has_parent_company?
  end

  def is_parent_company?
    Company.where(parent_company_id: self.id).exists?
  end

  def family_users(opts={})
    if opts[:includes]
      User.includes(opts[:includes]).where(company_id: self.family.map(&:id))
    else
      User.where(company_id: self.family.map(&:id))
    end
  end

  def managers(with_atleast_one_active_report: false)
    report_query = self.users
    report_query = report_query.not_disabled if with_atleast_one_active_report
    manager_ids = report_query.select('DISTINCT users.manager_id')
    self.users.where(id: manager_ids)
  end

  def update_badges!(badge_params)
    badges = badge_params.map do |badge_id, attrs|
      short_name, points, enabled, description, sort_order = attrs["short_name"], attrs["points"], attrs["enabled"], attrs["description"], attrs["sort_order"]
      sending_frequency, sending_interval_id, is_nomination = attrs["sending_frequency"], attrs["sending_interval_id"], attrs["is_nomination"]
      sending_limit_scope_id = attrs["sending_limit_scope_id"]
      point_values, approver, approval_strategy = attrs["point_values"], attrs["approver"], attrs["approval_strategy"]

      # nomination badges cannot be sent instantly, so override params["is_instant"]
      if is_nomination
        attrs["is_instant"] = "false"
      end

      updates = { short_name: short_name, points: points, description: description, long_description: attrs["long_description"], sort_order: sort_order }
      updates[:disabled_at] = (enabled == "true" ? nil : Time.now)

      updates[:allow_self_nomination] = (attrs["allow_self_nomination"] == "on")
      updates[:is_instant] = (attrs["is_instant"] == "true")
      updates[:show_in_badge_list] = (attrs["show_in_badge_list"] == "true")
      updates[:force_private_recognition] = (attrs["force_private_recognition"] == "true")
      updates[:requires_approval] = (attrs["requires_approval"] == "true")
      updates[:is_achievement] = (attrs["is_achievement"] == "on")
      updates[:sending_frequency] = sending_frequency
      updates[:sending_interval_id] = sending_interval_id
      updates[:is_nomination] = attrs["is_nomination"] || false if self.allow_nominations?
      updates[:nomination_award_limit_interval_id] = attrs["nomination_award_limit_interval_id"] if self.allow_nominations?
      updates[:is_quick_nomination] = attrs["is_quick_nomination"] if self.allow_nominations?
      updates[:sending_limit_scope_id] = sending_limit_scope_id

      if updates[:requires_approval] == true
        updates[:point_values] = point_values
        updates[:approval_strategy] = approval_strategy == "false" ? nil : approval_strategy.to_i
        updates[:approver] = approver.to_i
      end

      if updates[:is_achievement] == true && allow_achievements?
        updates[:achievement_frequency] = attrs["achievement_frequency"].to_i
        updates[:achievement_interval_id] = attrs["achievement_interval_id"].to_i
      end

      # Badge.where(id: badge_id).update_all(updates)

      badge = Badge.where(company_id: self.id, id: badge_id).first

      begin

        transaction do
          badge.update!(updates)
          new_roles = self.company_roles.where(id: attrs["roles"]).to_a
          badge.grant_permission_to_roles(:send, new_roles)
        end
        Badge.update_cache!(badge_id)

      rescue
        # noop
      end

      badge
    end

    result = RecognizeOpenStruct.new(success: badges.all?{|b| b.errors.size == 0}, badges: badges)

    # we may have changed badge point values, and thus need to update everyone's point totals
    SafeDelayer.delay(queue: 'points').run(Company, self.id, :refresh_all_user_point_totals!) if result.success
    # self.delay(queue: 'points').refresh_all_user_point_totals! if result.success

    return result
  end

  def custom_badges_enabled?
    self.custom_badges_enabled_at.present?
  end

  def enable_custom_badges!
    raise "Cannot enable custom badges twice" if custom_badges_enabled?
    raise "Company must first be saved before enabling custom badges" unless self.persisted?

    set = []
    user_badges = child_company? ? self.parent_company.company_badges : Badge.all_user_badges
    user_badges = user_badges[0..3] if Rails.env.test? #Hack to speed up tests, we dont need 30 badges enabled
    user_badges.each_with_index do |b, i|
      Rails.logger.info "Cloning badge(#{self.id}) #{i}/#{user_badges.size}"
      set << b.clone_to_custom
    end
    Rails.logger.info "Assigning cloned badges(#{self.id})"
    self.badges = []
    set.each do |b|
      begin
        b.company_id = self.id
        b.save!
      rescue Exception => e
        Rails.logger.warn "Caught exception enabling custom badges: #{e} - #{self.badges.inspect} - #{set.inspect}"
        Rails.logger.warn "Errors(#{b.name}): #{b.errors.full_messages.to_sentence}"
        raise e
      end
    end
    touch(:custom_badges_enabled_at)

    # update all recognitions that were sent from this company to have proper badge id
    self.badges.each do |b|
      Recognition.where(sender_company_id: self.id, badge_id: b.original_id).update_all(badge_id: b.id)
      # Recognition.update_all(["badge_id = ?", b.id], ["sender_company_id = ? AND badge_id = ?", self.id, b.original_id])
    end
  end

  def enable_admin_dashboard!
    update_attribute(:allow_admin_dashboard, true)
  end

  def compile_theme!
    CustomTheme.delay(queue: 'themes').compile_theme!(self.id)
  end

  def has_theme?
    super && !self.custom_theme.compiling_in_progress?
  end

  def enable_achievements!
    update_attribute(:allow_achievements, true)
  end

  def update_price_package(price_package)
    price_package = nil if price_package == "null"
    update(price_package: price_package)
  end

  def show_achievements?
    allow_achievements? && has_achievement_badges?
  end

  def has_achievement_badges?
    self.company_badges.achievements.size > 0
  end

  def has_sent_or_received_recognitions?

    # first condition checks a recognition was sent via the web platform
    result = self.recognitions.joins(:sender)
                 .non_system
                 .where(from_inbound_email_id: nil)
                 .where("recognitions.created_at >= users.verified_at")
                 .count

    result > 0

    # second condition checks against edge case where maybe there were multiple
    # recognitions sent via email, in most cases once recognitions start being sent
    # we'll never reach the 2nd condition, so only 1 query will be executed
    # self.recognitions.non_system.where.not(from_inbound_email_id: nil).count > 1

  end

  def email
    company_admin.email
  end

  def company_admins
    @company_admins ||= users_with_company_admin_role.not_disabled
  end

  def company_admin
    # [Edge case] A company should in theory always have a company admin who is an active user, but it is currently
    # possible in the application for a company admin to disable herself - so be defensive using the latter OR
    # expression.
    @company_admin ||= company_admins.first || users_with_company_admin_role.first
  end

  def recognitions(reload=false)
    # sniff, sniff...this code smells...
    if reload
      @recognitions = Recognition.for_company(self)
    else
      @recognitions ||= Recognition.for_company(self)
    end
  end

  def recognitions_for_badge(badge_id)
    recognitions.not_private.approved.where(badge_id: badge_id)
  end

  def to_param
    self.domain
  end

  def all_users_cache_key
    "company-#{id}-all_users"
  end

  def refresh_cached_users!

    begin
      self.reload #make sure we have latest data
      Rails.cache.write(all_users_cache_key, all_users)
    rescue TypeError
      # DelayedJob may choke with 'TypeError: singleton can't be dumped'
      user_set = Company.find(self.id).all_users
      Rails.cache.write(all_users_cache_key, user_set)
    end
  end

  def cached_users(opts={})
    return all_users if opts[:skip_cache]
    Rails.cache.fetch(all_users_cache_key, opts[:cache]) { all_users }
  rescue TypeError => e
    au = self.all_users
    Rails.logger.warn("CACHE ERROR: #{e}")
    Rails.logger.warn("#{au.inspect}")
    return au
  end

  def all_users
    # NOTE: there is some problem with Marshal.dump on sets of users
    #       that have the association cache set(ie when loaded via relation[company.users])
    #       This method is used to cache a companies users, so we need to load the user set
    #       directly without the association cache being set so we can Marshal it without errors
    user_set = User.where(company_id: self.id).where.not(id: User.system_user.id)
    (user_set + yammer_users).uniq{|u| (u.email.present? ? u.email : u.phone)}.reduce({}) do |hash, user|
      user.disabled? ? hash : (hash[user.email || user.phone] = user; hash)
    end
  end

  def self.beta_domain?(domain)
    return false if domain.blank?
    BETA_DOMAINS.any? { |d| domain.match(d) }
  end

  def beta_domain?
    Company.beta_domain?(self.domain)
  end

  def has_one_verified_user?
    self.users.any? { |u| u.verified? }
  end

  def self.from_email(email)
    return nil unless email.index("@")
    domain = email.split("@").last
    self.from_domain(domain)
  end

  def self.from_domain(domain)
    c = CompanyDomain.joins(:company).includes(:company).find_by(domain: domain).try(:company)
    c ||= Company.new(domain: domain).tap { |co| co.slug = domain }
    c.name = domain.split(".")[0..domain.count('.')-1].map { |w| w.capitalize }.join(' ') unless c.persisted? #default name is the domain split out sans the tld
    return c
  end

  def self.attributes_for_json
    @@json_attributes ||= [:id, :name, :slug, :domain]
  end

  # def self.has_other_users_in_domain?(user)
  #   user_domain = User.blacklisted_email?(user.email) ?
  #       "users" :
  #       user.email.split("@")[1]

  #   company = where(domain: user_domain).first
  #   company and company.users.where("users.id <> #{user.id}").present?
  # end

  def self.has_other_users_in_domain?(user)
    company = if User.blacklisted_email?(user.email)
                find_by(domain: "users")
              elsif user.company
                user.company
              else
                from_email(user.email)
              end
    company.users.reset.where.not(id: user.id).exists?
  end

  def company_theme_id
    self.slug.gsub(".", "_")
  end

  def custom_theme
    CustomTheme.new(self)
  end

  def has_team?(name)
    self.teams.any? { |t| t.name == name }
  end

  def disabled?
    disabled_at.present?
  end

  def disable!
    self.update_attribute(:disabled_at, Time.now)
  end

  def active?
    !disabled? and deleted? and has_one_verified_user?
  end

  def has_one_active_user?
    self.users.any { |u| u.active? }
  end

  def self.prime_caches!
    Company.scoped.each do |c|
      c.prime_caches!
    end
  end

  def prime_caches!(prime_user_caches: true)
    self.refresh_cached_users!
    Rails.logger.debug "#{Time.now.to_formatted_s(:db)} - Refreshing cached users for(#{self.domain})"
    if prime_user_caches
      self.users.each do |u|
        u.delay(queue: 'caching').prime_caches!
      end
    end
    self.refresh_cached_yammer_groups!
  end

  def calculate_received_recognitions_count
    Recognition.joins(:recognition_recipients).
        where(recognition_recipients: { recipient_company_id: self.id }).count(:id)
  end

  def calculate_received_user_recognitions_count
    Recognition.joins(:recognition_recipients).
        where(recognition_recipients: { recipient_company_id: self.id }).
        where("recognitions.badge_id NOT IN (?)", Badge.system_badges.pluck(:id)).count
  end

  def calculate_sent_user_recognitions_count
    Recognition.where(["sender_company_id = ? AND badge_id NOT IN (?)", self.id, Badge.system_badges.pluck(:id)]).size
  end

  def update_received_recognitions_counter_cache!
    self.update_attribute(:received_recognitions_count, self.calculate_received_recognitions_count)
  end

  def update_received_user_recognitions_counter_cache!
    self.update_attribute(:received_user_recognitions_count, self.calculate_received_user_recognitions_count)
  end

  def update_sent_recognitions_counter_cache!
    Company.where(id: self.id).update_all(sent_recognitions_count: self.sent_recognitions.count)
  end

  def update_sent_user_recognitions_counter_cache!
    self.update_attribute(:sent_user_recognitions_count, self.calculate_sent_user_recognitions_count)
  end

  def update_recognition_limits(params)
    attrs = %i[default_recognition_limit_interval_id
               default_recognition_limit_frequency
               default_recognition_limit_scope_id
               recognition_limit_interval_id
               recognition_limit_frequency
               recognition_limit_scope_id]
    self.assign_attributes(params.slice(*attrs))
    self.save
  end

  def update_kiosk_mode_key(key)
    self.kiosk_mode_key = key
    self.save
  end

  def kiosk_mode_key_contains_proper_characters
    if kiosk_mode_key.present? && (!kiosk_mode_key.match(/^[a-zA-z0-9]+$/))
      errors.add(:kiosk_mode_key, I18n.t("activerecord.errors.models.company.kiosk_key_format"))
    end
  end

  COUNTER_CACHES = {
      :update_received_recognitions_counter_cache! => :received_recognitions_count,
      :update_received_user_recognitions_counter_cache! => :received_user_recognitions_count,
      :update_sent_user_recognitions_counter_cache! => :sent_user_recognitions_count
      # :update_sent_recognitions_counter_cache!, :update_users_counter_cache!
  }

  def refresh_all_counter_caches!
    COUNTER_CACHES.keys.each do |m|
      self.send(m)
    end
    self.attributes.keys.each do |attr|
      next unless attr.match(/_count$/)
      next if COUNTER_CACHES.value?(attr.to_sym)
      # explicitly skip disabled counter caches
      # FIXME - remove these attributes
      # Ugh, this is terrible...2016/01/30
      next if [:sent_recognitions_count, :requested_user_count].include?(attr.to_sym)
      Company.reset_counters(self.id, attr.gsub(/_count$/, ''))
    end
  end

  def last_accounts_spreadsheet_import_results_document
    Document.find_by_id(last_accounts_spreadsheet_import_results_document_id)
  end

  def last_accounts_spreadsheet_import_summary
    last_accounts_spreadsheet_import_results_document&.metadata
  end

  def refresh_all_user_point_totals!
    self.users.each do |u|
      u.delay(queue: 'points').update_all_points!
    end
    Report::CacheManager::Company.delay(queue: 'priority_caching').bust_and_reprime_report_caches!(self.id)
  end

  def update_global_privacy(privacy)
    flag = (privacy.downcase == "on")
    self.update_attribute(:global_privacy, flag)
  end

  def allows_public_recognitions?
    !self.global_privacy? && self.allow_admin_dashboard?
  end

  def allows_private_recognitions?
    self.allows_private?
  end

  def requires_recognition_tags?
    self.show_recognition_tags? && self.settings.require_recognition_tags? && self.tags.recognition_taggable.present?
  end

  def allow_yammer_stats?
    self.permit_yammer_stats? && # superadmin setting
    self.enable_yammer_stats?    # company self setting
  end

  def permit_yammer_stats!
    update_column(:permit_yammer_stats, true)
  end

  def top_badges(opts={})
    Badge.top_badges_for_company(self, opts)
  end

  def users_by_status
    User.users_by_status_for_company(self.id)
  end

  def update_settings!(settings)
    if settings.has_key?("global_privacy")
      privacy_on_off = (settings["global_privacy"] == "true" ? "on" : "off")
      update_global_privacy(privacy_on_off)
    else
      settings.each do |name, value|
        if value.kind_of?(Hash)
          association = self.send(name)

          if association.blank?
            self.send("build_#{name}")
            association = self.send(name)
          end

          value.each do |key, val|
            if name == 'settings' && key.in?(%w[sync_filters recognition_editor_settings])
              val = parse_serialized_setting(key, val)
            end
            association.send("#{key}=", val)
          end

          association.save!
        else
          self.send("#{name}=", value)
        end
      end
    end
    save!
  end

  def get_user_ids_by_role_id(role_id, include_disabled: false)
    user_ids = Role.company_user_ids_by_role_id(self, role_id, include_disabled: include_disabled)
  end

  def get_user_ids_by_company_role_id(role_id, include_disabled: false)
    # cr = CompanyRole.find(role_id)
    # users = cr.users
    # users = users.not_disabled unless include_disabled
    # user_ids = users.pluck('id')
    # return user_ids
    return get_user_ids_by_company_role_ids([role_id], include_disabled: include_disabled)
  end

  def get_user_ids_by_company_role_ids(role_ids, include_disabled: false)
    users = User.joins(:user_company_roles)
      .where(company_id: self.id)
      .where(user_company_roles: {company_role_id: role_ids})

    users = users.not_disabled unless include_disabled

    users.distinct(:id).pluck(:id)
  end

  def get_users_by_company_role_id(role_id)
    users = User.joins(:user_company_roles)
      .where(company_id: self.id)
      .where(user_company_roles: {company_role_id: role_id})

    users = users.not_disabled

    users.distinct(:id)
  end

  def get_users_with_no_company_roles(include_disabled: false)
    users = User.where(company_id: self.id)
                .includes(:user_company_roles)
                .where(user_company_roles: { user_id: nil })

    include_disabled ? users : users.not_disabled
  end

  def self.reset_intervals
    Interval::RESET_INTERVALS
  end

  def default_recognition_limit_interval
    @default_recognition_limit_interval ||= Interval.new(default_recognition_limit_interval_id)
  end

  def recognition_limit_interval
    @recognition_limit_interval ||= Interval.new(recognition_limit_interval_id)
  end

  def add_external_user!(inviter, attributes, send_invitation: true)
    user = self.users.build(attributes)
    user.skip_same_domain_check = true

    inviter.send(:add_user!, user, nil, skip_invitation: !send_invitation)
    user
  end

  # DEPRECATED 6/13/2017
  # def resend_invitations!(sender, status=:pending_invite)
  #   set = self.users.where(status: status)
  #   set.each do |user|
  #     sender.resend_invite!(user)
  #   end
  # end

  def self.sync_enabled
    where(sync_enabled: true, allow_admin_dashboard: true).where.not(sync_provider: "sftp")
  end

  def sync_groups(provider: )
    provider.to_sym == :yammer ?
      settings.yammer_sync_groups :
      settings.microsoft_graph_sync_groups
  end

  def admin_sync_user(provider: self.sync_provider)
    users = self.company_admins.select{|u| u.authentications.send(provider).present? }
    users = users.select{|u| u.microsoft_graph_admin? }.presence if provider.to_sym == :microsoft_graph
    return users.try(:last)
  end

  def can_configure_sync?(provider, user)
    provider = provider.to_sym
    return true if provider == :sftp

    can_configure = admin_sync_user(provider: provider).present?

    if provider == :microsoft_graph
      can_configure &&= can_configure_microsoft_graph_sync?
      can_configure &&= user.microsoft_graph_admin?
    elsif provider == :yammer
      can_configure &&= user.authentications.yammer.present?
    end

    return can_configure
  end

  def can_configure_microsoft_graph_sync?
    # a recognize admin may have auth'd with Microsoft Graph, but they may not have access token with admin rights
    admin_sync_user(provider: :microsoft_graph).microsoft_graph_admin?
  end

  def settings
    super || build_settings
  end

  # convenience method for support engineers
  def user_syncer
    case self.sync_provider.to_sym
    when :microsoft_graph
      UserSync::MicrosoftGraph.new(company: self, sync_initiator: self.admin_sync_user)
    when :yammer
      UserSync::Yammer.new(company: self, sync_initiator: self.admin_sync_user)
    else
      nil
    end
  end

  def currency_prefix(opts = {})
    Rewards::Currency.currency_prefix(currency, opts)
  end

  def principal_catalog
    @principal_catalog ||= ( catalogs.where(currency: currency).first || catalogs.first )
  end

  def eligible_for_engagement_report_mailer?(role)
    return false unless Subscription.feature_permitted?(self, nil, :manager, skip_user_check: true)

    send("allow_#{role}_report_mailer?")
  end

  def saml_enabled_and_forced?
    self.saml_enabled? && self.settings.force_sso?
  end

  def allow_syncing_of_user_attributes_mapped_to_custom_field_mapping?
    self.settings.allow_custom_field_mapping? &&
      self.settings.sync_custom_fields? &&
      self.custom_field_mappings.custom_field_mapping.present? &&
      self.custom_field_mappings.custom_field_mapping.any? { |cfm| cfm.mapped_to.present? }
  end

  def deliver_webhook_event(event_name, object)
    return unless self.settings&.allow_webhooks?
    
    self.webhook_endpoints.not_disabled.for_event(event_name).each do |endpoint|
      endpoint.deliver(event_name, object)
    end
  end

  protected

  def create_default_teams
    set = []
    Team.default_set.each do |team_name|
      set << Team.new(name: team_name).tap { |t| t.company = self }
    end
    transaction do
      set.map { |team| team.save! }
    end
    self.teams = set
  end

  def run_settings_callbacks
    SETTINGS.each do |setting|
      if send("saved_change_to_#{setting}?") && respond_to?("#{setting}_has_changed!", true)
        send("#{setting}_has_changed!")
      end
    end
  end

  def allow_daily_emails_has_changed!
    if self.allow_daily_emails?
      user_ids = self.users.pluck(:id)
      EmailSetting.where(user_id: user_ids).update_all(daily_updates: true)
    end
  end

  def reset_interval_has_changed!
    Points::Resetter.new(self).reset!
  end

  def set_default_company_name
    self.name = self.domain if self.name.blank?
  end

  def set_new_company_secure_defaults
    return if self.id == 1 && Rails.env.test? # hack for tests
    self.default_recognition_limit_frequency = 10
    self.default_recognition_limit_interval_id = Interval.daily.to_i
    self.recognition_limit_frequency = 10
    self.recognition_limit_interval_id = Interval.daily.to_i
  end

  def initialize_company_domains
    self.domains.build(domain: self.domain) unless self.domains.present?
  end

  def check_subcompany_has_no_users
    if parent_company_id.present? && self.users.present?
      errors.add(:base, "Cannot delete department while there are users. Please reassign users to a different department.")
      return false
    end
  end

  # This should only be encountered in edge cases (since the relevant iOS checkbox is disabled in this case)
  def verify_badges_when_disallowing_private_recognitions
    if changes[:allows_private] == [true, false] && badges.with_forced_privacy.exists?
      errors.add(:allows_private, "Cannot disable private recognitions while there are badges that force it.")
    end
  end

  private

  def attributes_uninheritable_by_child_company
    %i[
      custom_badges_enabled_at
      last_accounts_spreadsheet_import_file
      last_accounts_spreadsheet_import_problematic_records_file
      last_accounts_spreadsheet_import_results_document_id
    ]
  end

  # Note: Includes users with company admin role that might not necessarily be active user.
  def users_with_company_admin_role
    self.users.joins(:user_roles).includes(:user_roles).where(user_roles: {role_id: Role.company_admin.id})
  end

  def parse_serialized_setting(key, value)
    case key
    when 'recognition_editor_settings'
      parse_recognition_editor_settings(value)
    when 'sync_filters'
      parse_sync_filter(value)
    else
      raise 'Unknown serialized setting'
    end
  end

  # processes new editor settings, merging with existing settings hash.
  def parse_recognition_editor_settings(new_hash)
    settings_hash = self.settings.recognition_editor_settings

    new_hash.each do |sub_setting, val|
      next unless %w[true false].include?(val)
      casted_value = (val == 'true')
      settings_hash[sub_setting.to_sym] = casted_value
    end

    settings_hash
  end

  # processes new filter value, merges it into existing sync_filters hash and returns the updated hash
  # for now, there is only one filter
  def parse_sync_filter(filter_hash)
    filters = self.settings.sync_filters

    ms_graph_account_enabled_filter = filter_hash.dig(:microsoft_graph, :accountEnabled)
    if %w[true false].include?(ms_graph_account_enabled_filter)
      casted_value = (ms_graph_account_enabled_filter == 'true')
      filters[:microsoft_graph] ||= {} # to be safe
      filters[:microsoft_graph][:accountEnabled] = ['equals', casted_value] # add predicate structure
    end

    filters
  end
end
