class Recognition < ApplicationRecord
  include ActiveModel::ForbiddenAttributesProtection
  include ActionView::Helpers::TextHelper
  include RecognitionConcern
  include TimestampConcern
  include Points::Calculator::CommonMethods
  include IntervalHelper
  include PostConcern

  acts_as_paranoid
  enable_duplicate_request_preventer

  class LimitScope
    include IdNameMethods
    DATA =  [
      [ SCOPE_LIMIT_BY_RECOGNITIONS = 1, :recognition, "Recognitions"],
      [ SCOPE_LIMIT_BY_USERS = 2, :user, "Users"]
    ]
    def recognition?
      self.id == SCOPE_LIMIT_BY_RECOGNITIONS
    end

    def user?
      self.id == SCOPE_LIMIT_BY_USERS
    end
  end

  include Rails.application.routes.url_helpers
  attr_accessor :recipient_emails, :allow_guest_access, :experiment_value, :affected_participant_ids
  attr_accessor :reference_recipient # gives ability to tag a recognition with the recipient we want to focus on(eg for reporting on individuals across a set)
  attr_accessor :reference_recipient_teams
  attr_accessor :reference_activity # also do the same for stashing the point activity we're referencing
  attr_accessor :reference_recognition_tags # also do the same for stashing the recognition tags we're referencing
  attr_accessor :reference_recipient_nominated_badge_ids
  attr_accessor :badge_name
  attr_accessor :has_send_limit_error
  attr_accessor :skip_send_limits

  # This needs to be set above recognition_recipients,
  # so that association callbacks are not executed first
  # thus destroying the association before we have a chance to stash it
  before_destroy :set_affected_participants

  belongs_to :sender, -> { with_deleted }, :class_name => "User", counter_cache: :sent_recognitions_count, optional: true
  belongs_to :sender_company, class_name: "Company", counter_cache: :sent_recognitions_count, optional: true
  belongs_to :badge, optional: true
  has_many :comments, as: :commentable
  has_many :recognition_recipients, inverse_of: :recognition, dependent: :destroy do
    def for_user(user)
      detect{|rr| rr.user_id == user.id}
    end
  end
  has_many :user_recipients, -> { distinct }, through: :recognition_recipients, source: :user
  has_many :point_activities, dependent: :destroy
  has_many :recognition_tags, inverse_of: :recognition, dependent: :destroy
  has_many :tags, through: :recognition_tags

  before_validation :convert_recipient_emails_to_user
  before_validation :ensure_skipping_user_name_validation
  before_validation :strip_placeholder
  before_validation :strip_empty_tags_around_html_message
  before_validation :strip_duplicate_recipients
  before_validation :convert_badge_name_to_badge
  before_validation :set_message_plain
  # this used to be before_create (originally after_create), but with the use of authoritative_company for validations
  # this attribute (sender_company) should now be set before validation, as authoritative_company falls back on it
  before_validation :ensure_company
  # Just for the api. This is a temporary placeholder, until we update the mobile app to allow selection of yammer group
  before_validation :deduce_post_to_yammer_group_id, if: -> { self.post_to_yammer_wall && self.viewer == "api_v2" }

  before_create :set_cross_company_attribute
  before_create :set_privacy
  before_create :set_approved_at

  after_create :after_create_async_service
  after_create :generate_slug

  after_save :after_save_async_service

  after_destroy :update_user_recognitions_counter_cache
  after_destroy :update_participant_point_totals! # FIXME: this may be unnecessary as its handled by RecognitionObserver.

  after_commit :after_commit_async_service, on: %i[update create], if: :status_changed_to_approved_and_not_deleted?
  after_commit :publish_recognition_pending, on: :create, if: :status_pending_and_not_deleted?

  validates :sender_id, :presence => true
  validates :sender_company_id, presence: true
  validates :message, presence: true, if: :should_require_message
  validates :badge_id, presence: { message: I18n.t("activerecord.errors.models.recognition.attributes.badge_id.blank") }
  validates :slug, uniqueness: { case_sensitive: true }
  validates :input_format, inclusion: { in: %w[text html] }
  # Just for the api. This is a temporary placeholder, until we update mobile app to allow selection of yammer group
  validates :post_to_yammer_group_id, presence: { message: I18n.t("activerecord.errors.models.recognition.attributes.post_to_yammer_group_id.blank") }, if: -> { self.post_to_yammer_wall? && self.viewer != "api_v2" }, on: :create

  validate :new_user_recipients_are_valid
  validate :cannot_send_to_self
  validate :cannot_send_to_teams_that_have_only_self
  validate :only_system_users_can_send_system_badges
  validate :check_recipient_or_email
  validate :check_teams_have_users
  validate :sender_has_permission_to_send_badge, on: :create
  validate :can_send_achievement_badge
  validate :is_within_sending_limits, on: :create, unless: :skip_send_limits
  validate :badge_name_is_valid
  validate :recipients_are_within_org
  validate :no_team_recipients_when_teams_disabled
  validate :exclude_sender_in_team_from_recognition_recipients
  validate :disallow_recognizing_disabled_user
  validate :privacy_and_social_sharing
  validate :message_size_is_within_limit
  validate :tags_are_present, if: :should_require_tags?
  # Not required for recognitions sent from UI; however, recognitions done via bulk import
  # can have emails of disabled user as sender.
  validate :disallow_recognition_from_disabled_user



  default_scope { order "recognitions.updated_at DESC, recognitions.id DESC" }

  scope :sent_by, lambda {|user| where(:sender_id => user.id)}
  scope :received_by, lambda {|user|
    includes(:recognition_recipients).joins(:recognition_recipients).
    where(recognition_recipients: {user_id: user.id})}

  # FIXME - not sure what the difference is between #user_sent and #non_system
  #         this should be consolidated - perhaps there should be a flag on badges
  #         that say "include_in_point_calculations" - and then these badges will be included
  #         in counters and point calculations - this will account for the future when we
  #         want auto sent badges to be included in point calculations and allow companies to specify
  #         certain badges from avoiding this
  scope :user_sent, lambda{ where("badge_id NOT IN (?)", Badge.system_badges.collect{|b| b.id})}
  scope :non_system, lambda{where("recognitions.sender_id <> ?", User.system_user.id)}
  scope :not_private, lambda{ where(is_private: false) }
  scope :pending_approval, -> { where(status_id: status_id_by_name(:pending_approval)) }
  scope :approved, -> { where(status_id: status_id_by_name(:approved)) }
  scope :not_denied, -> { where.not(status_id: status_id_by_name(:denied)) }
  scope :denied, -> { where(status_id: status_id_by_name(:denied)) }
  # apply only for non system user sender
  scope :sender_active, lambda {
    joins("INNER JOIN users AS sender ON sender.id = recognitions.sender_id INNER JOIN user_roles AS ur ON ur.user_id = sender.id")
      .where("sender.status='active' OR ur.role_id = ?", Role.system_user.id) }
  scope :recipients_active, -> { includes(recognition_recipients: :user).where(recognition_recipients: { users: { status: :active } })  }

  def self.attributes_for_json
    @@json_attributes ||= [:id, :sender_company_id, :badge_id, :sender_id, :message, :message_plain,
                           :permalink, :badge_permalink, :to_param, :requires_approval]
  end

  INSTANT_RECOGNITION_MESSAGES=[
    "You\'re doing great work.",
    "Good job on your recent work.",
    "You deserve recognition for your work. Congrats.",
    "Thanks for doing a fantastic job.",
    "Your work is appreciated."
  ]

  def self.instant(sender, params)
    r = self.new
    r.viewer = params[:viewer]
    r.viewer_description = params[:viewer_description]
    r.is_instant = true
    r.sender = sender
    r.badge = Badge.random_from_instant(sender.company)
    r.message = params[:message] || INSTANT_RECOGNITION_MESSAGES[rand(INSTANT_RECOGNITION_MESSAGES.length)]

    if params[:email].present?
      user = User.where(email: params[:email]).first_or_initialize
      user.yammer_id = params[:yammer_id] if params[:yammer_id].present?
    else
      # we don't have email, because of glorious yammer's api to return inconsistent objects
      # so we have to fetch the email seperately, and then determine if they are in our system

      user = User.from_yammer(sender.yammer_client.get_user(params[:yammer_id]))
      raise ArgumentError, "Could not find user by yammer id; they may not be in your network" unless user.present?

      # check if user is already in the system
      if user = User.where(email: user.email).first_or_initialize
        # this could be dry'd up
        user.yammer_id = params[:yammer_id] if params[:yammer_id].present?

      end
    end

    user.set_status!(:invited_from_recognition) unless user.persisted? && user.active?

    r.add_recipient(user)

    return r
  end

  def self.for_company(c)
    Recognition.where(authoritative_company_id: c.id).distinct
    # unless c.custom_badges_enabled_at.present?
    #   Recognition
    #     .joins("INNER JOIN recognition_recipients as rrs ON rrs.recognition_id = recognitions.id")
    #     .where("rrs.sender_company_id = ? OR rrs.recipient_company_id = ?", c.id, c.id)
    #     .distinct
    # else
    #   # Recognition.joins(:badge).where(badges: {company_id: c.id}).distinct
    #   Recognition.where(authoritative_company_id: c.id).distinct
    # end


    # q1 = "select recognitions.* from recognitions INNER JOIN recognition_recipients ON recognition_recipients.recognition_id = recognitions.id where recognition_recipients.sender_company_id = #{c.id}"
    # q2 = "select recognitions.* from recognitions INNER JOIN recognition_recipients ON recognition_recipients.recognition_id = recognitions.id where recognition_recipients.recipient_company_id = #{c.id}"
    # Recognition.find_by_sql("#{q1} UNION #{q2}")

      # Recognition.joins(:recognition_recipients)
      #   .where("recognition_recipients.sender_company_id = ? OR recognition_recipients.recipient_company_id = ?", c.id, c.id)
    # RecognitionRecipient.joins(:recognition).where("recognition_recipients.sender_company_id = #{c.id} OR recognition_recipients.recipient_company_id = #{c.id}")

    # r, rr = ::Recognition.arel_table, ::RecognitionRecipient.arel_table
    # includes(:recognition_recipients).references(:recognition_recipients)
    # .where(rr[:sender_company_id].eq(c.id).or(rr[:recipient_company_id].eq(c.id)))

  end
    # Recognition
    #   .joins("INNER JOIN recognition_recipients ON recognition_recipients.recognition_id = recognitions.id")
    #   .where("recognition_recipients.deleted_at IS NULL")
    #   .where("recognition_recipients.sender_company_id = ? OR recognition_recipients.recipient_company_id = ?", c.id, c.id)

  def self.for_companies(ids)
    # scope = Recognition.select("recognitions.*")
    Recognition.scoped_to_companies(ids).distinct
  end

  def self.scoped_to_companies(ids)
    r, rr, u, t= Recognition.arel_table, RecognitionRecipient.arel_table, User.arel_table, Team.arel_table
    scope = Recognition.joins(:recognition_recipients)
    return scope.where(r[:sender_company_id].in(ids).or(rr[:recipient_company_id].in(ids)))
  end

  def self.sent_or_received_by(user)
    return where(:id => nil).where("id IS NOT ?", nil) unless user.persisted?
    r, rr = ::Recognition.arel_table, ::RecognitionRecipient.arel_table
    includes(:recognition_recipients).references(:recognition_recipients)
    .where(r[:sender_id].eq(user.id).or(rr[:user_id].eq(user.id)))
    .where(rr[:deleted_at].eq(nil))
  end

  # This is the company that should be considered when checking settings
  def authoritative_company
    @authoritative_company ||= begin
      if self.badge&.company_id.present?
        Company.unscoped { self.badge.company }

      # System user senders include anniversaries and the first ambassador badge
      # It is an edge case for anniversaries because they should have custom badges enabled
      # and thus should hit the above conditional
      # However, recognitions for the ambassador badge are sent during signup
      # and thus do not have custom badges enabled yet
      # Regardless, pick the first user recipient
      elsif self.sender&.system_user?
        # there are definitely odd cases where the recognition is left around
        # but the recipients have deleted_at set
        # We don't care about that here. If we have a recognition object,
        # return the recipients even if they have been "deleted"
        Company.unscoped { User.unscoped{ self.user_recipients.first&.company }}
      else
        # This is a bit of a weird branch. Not sure if or when we'll hit this
        # But the latter part of the || was added to get a test to pass spec/models/recognition_spec.rb
        Company.unscoped{ self.sender_company || self.sender&.company}
      end
    end
  end

  def badge=(new_badge)
    case new_badge
    when String
      self.badge_name = new_badge
    else
      super
    end
  end

  def participant_company_ids
    participants.collect(&:company_id)
  end

  def participant_ids
    participants.collect{|p| p.id}
  end

  # sender + recipients
  def participants(include_system_user: false)
    participants = self.flattened_recipients
    participants += [self.sender] unless self.sender.system_user? && !include_system_user
    # be defensive against nil objects in participants
    participants.uniq.reject(&:blank?)
  end

  def earned_points_calculated_off_point_activities
    # Safe navigation operator `&` is used here, since system_user sent recognitions don't have point activities.
    point_activities.where(activity_type: "recognition_recipient").first&.amount
  end

  def recipients(opts={})
    set = opts[:with_deleted] ? recognition_recipients.with_deleted : recognition_recipients
    set.includes(:user)
      .joins(:user)
      .reject{|u| u.team_id.present? || u.company_id.present?}
      .map(&:user) + team_recipients + company_recipients
  end

  def user_recipients
    return super if association(:user_recipients).loaded?
    return super.with_deleted if self.deleted?

    if association(:recognition_recipients).loaded?
      self.recognition_recipients.map(&:user).uniq
    else
      super
    end
  end

  def team_recipients
    set = self.deleted? ? recognition_recipients.with_deleted : recognition_recipients
    team_ids = set.where.not(team_id: nil).pluck(:team_id)
    Team.unscoped.find(team_ids)
  end

  def company_recipients
    set = self.deleted? ? recognition_recipients.with_deleted : recognition_recipients
    company_ids = set.where.not(company_id: nil).pluck(:company_id)
    Company.find(company_ids)
  end


  def flattened_recipients
    user_recipients.reject(&:blank?)
  end

  def add_recipient(recipient)
    case recipient
    when User
      recipient.set_status!(:invited_from_recognition) if !recipient.persisted? || recipient.pending_invite?
      self.recognition_recipients << RecognitionRecipient.new(user: recipient)
    when Team
      @team_recipients ||= []
      @team_recipients << recipient
      users = recipient.users.not_disabled
      self.recognition_recipients += users.map{|user| RecognitionRecipient.new(team_id: recipient.id, user: user)}
    when Company
      @company_recipients ||= []
      @company_recipients << recipient
      users = recipient.users.not_disabled
      self.recognition_recipients += users.map{|user| RecognitionRecipient.new(company_id: recipient.id, user: user)}
    when String
      if recipient.match(/\@/)
        self.recipient_emails ||= []
        self.recipient_emails <<  recipient
      elsif recipient.match(/\:/)
        add_recipient(Recognition.find_recipient_from_signature(recipient))
      elsif recipient.strip.match(/\A\+?\s*(\d[\s-]*)+[\d]\z/) # check for phone number
        phone_users = User.search_by_phone(recipient)
        phone_user = phone_users.detect { |u| u.network == self.sender.try(:network) } || phone_users.first
        raise ::Exceptions::UnknownPhoneUser, "User with given phone not found: #{recipient}" unless phone_user
        add_recipient(phone_user)
      else
        add_recipient(User.new(email: recipient))
        # raise "Recipient type: #{recipient.class} not supported!"
      end

    else
      raise "Recipient type: #{recipient.class} not supported!"
    end
  end

  def recipients=(set)
    Array(set).each do |r|
      next unless r.present?
      add_recipient(r)
    end
    return set
  end

  def to_param
    self.slug || ""
  end

  def recognize_hashid
    self.slug # for api compatibility
  end

  def self.find(param, other=nil)
    # force an integer if possible. 
    # This covers strings like "2" still using the normal lookup. 
    # This is specifically to address issue with GlobalId lookups
    # which will end up sending through a string integer. 
    param = Integer(param) rescue param 
    case param
    when Integer
      super(param)
    else
      self.find_from_param(param)
    end
  end

  def self.find_from_param(param)
    where(slug: param).first
  end

  def self.find_from_param!(param)
    find_from_param(param) or raise ActiveRecord::RecordNotFound
  end

  def post_to_yammer_wall!(group_id_to_post_to: )
    return if self.skip_notifications

    if u = self.sender and u.can_post_to_yammer_wall? and self.post_to_yammer_wall?
      msg = [self.message_plain.presence, recognition_tags_as_hashtags.presence].compact.join("\n")
      opts = yammer_og_object
      opts[:group_id] = group_id_to_post_to if group_id_to_post_to.present?
      u.yammer_client.create_message(msg, opts)
    end
  rescue => e
    Rails.logger.debug "Caught exception posting to yammer wall: #{e.message}"
    ExceptionNotifier.notify_exception(e)
    false
  end

  def social_title
    "#{self.recipients_label} with the #{self.badge.short_name} badge"
  end

  def summary_label
    sender_label = self.sender.system_user? ? self.authoritative_company.name : self.sender.full_name
    "#{sender_label} recognized #{self.recipients_label} with the #{self.badge.short_name} badge"
  end
  
  # for yammer
  def recognition_tags_as_hashtags
    return "" unless self.recognition_tags.present?
    self.recognition_tags
      .map { |rt| rt.tag_name.downcase.prepend("#").gsub(" ", "_") }
      .join(", ")
  end

  def skills_as_tags
    if skills.present?
      self.skills.split(",").select(&:present?).map{|skill| "##{skill.strip}"}.join(", ")
    else
      ""
    end
  end

  def yammer_og_object
    {
      og_url: self.permalink,
      og_image: self.badge_permalink(200, "http:"),
      og_title: social_title,
      og_description: self.message_plain
    }
  end

  def yammer_activity_object
    {
      type: "#{Recognize::Application.config.rCreds["yammer"]["namespace"]}:recognition",
      url: self.permalink,
      title: social_title,
      image: self.badge_permalink(200, "http:"),
      description: self.message_plain
    }
  end

  def cross_company?(user)
    self.sender_company_id != user.company_id
  end

  def has_proper_recipients_for_certificate?
    self.recipients.map(&:class).uniq.all? {|i| [User, Team].include?(i) }
  end

  # Ok here's the deal.
  # For reporting we need to be able to send a set of recognitions that reference unique recipients
  # I accomplish this in Report::Recognition#point_activity_query
  # I do so, by dup'ing a recognition, and assigning it a reference recipient
  # Essentially, this makes the recognition class a mock or a decorator or whatever pattern floats your boat.
  # I will copy over the created_at value
  #
  # NOTE: Do not use clone() here, because "modifying attributes of the clone will modify the original"
  #       Also, dup() does not copy any association cache (although it can be done manually)
  def dup_for_reference
    dup.tap do |r|
      r.created_at = self.created_at
      # r.id = nil # done by dup
      # r.instance_variable_set("@association_cache", self.instance_variable_get(:association_cache))
    end
  end

  def self.streamable_recognitions(args)
    ::StreamableRecognitions.call(args)
  end

  # This is a custom solution for optimizing the performance when filtering permitted recognitions from a large collection
  # It breaks the loop as soon as the required number of recognitions have been collected
  # Also uses custom batches, as an alternative to find_each (see https://stackoverflow.com/a/15190294)
  def self.select_permitted_recognitions_with_page_limit(base_query, page:, per_page:)
    batch = 250
    page = (page || 1).to_i
    records_needed = (page * per_page) + 1 # +1 here preserves the next_page link in pagination
    total_records = base_query.count
    total_records -= batch if total_records > batch

    [].tap do |permitted_recognitions|
      (0..total_records).step(batch) do |i|
        base_query.offset(i).limit(batch).each do |recognition|
          if recognition.permitted_to?(:show)
            permitted_recognitions << recognition
            return permitted_recognitions if permitted_recognitions.count >= records_needed
          end
        end
      end
    end
  end

  def set_privacy_to_company!(state)
    self.update_column(:is_public_to_world, state)
  end

  def has_invited_users?
    user_recipients.any?{|u| u.invited_from_recognition? }
  end

  def requires_approval
    self.badge.requires_approval
  end

  # Use update_point_activities_and_earned_points if you need to update point_activies amount
  #  along with earned_points.
  def update_earned_points
    self.update_column(:earned_points, earned_points_calculated_off_point_activities)
  end

  # Update point_activies and recalculates the earned_points.
  def update_point_activities_and_earned_points(new_points, force=false)
    # if new_points is lower than current earned_points then raise error unless we are forcing the update.
    #  NOTE: you should check to ensure points haven't been redeemed before forcing!
    if new_points < self.earned_points && force == false
      raise "New Points: #{new_points} is less than current Points: #{self.earned_points}, cannot reduce points without 'force' flag"
    else
      self.point_activities.where(activity_type: 'recognition_recipient').update_all(amount: new_points)
      update_earned_points
      self.user_recipients.map(&:update_all_points!)
    end
  end

  def comments_allowed?
    authoritative_company.settings.allow_comments?
  end

  def sender_name
    return unless self.persisted?
    return self.sender.full_name unless self.is_anniversary?

    if anniversary_recognition_custom_sender_name.present?
      anniversary_recognition_custom_sender_name
    else
      self.authoritative_company.name
    end
  end

  def sender_email
    self.is_anniversary? ? '' : self.sender.email
  end

  def formatted_from_email
    "#{self.sender_name.gsub(',','')} <donotreply@recognizeapp.com>"
  end

  # This is for backwards compatibility with recognitions
  # that already have a potentially improper cross company attribute
  # due to anniversary recognitions
  def is_cross_company?
    super && !is_anniversary?
  end

  def is_anniversary?
    !!badge&.is_anniversary?
  end

  def is_ambassador?
    !!(sender&.system_user? && badge&.ambassador?)
  end

  # Note: only the sender attribute is set when recognition is initialized during this auth check in setup_recognition()
  def image_upload_allowed?
    company = sender.company
    !!company.settings.recognition_editor_settings[:allow_uploading_images]
  end

  # This method keeps the message sanitization logic DRY and uniform throughout the site
  # Notes
  #   - :html_safe argument:
  #       The Rails sanitize() method marks strings as html_safe by default, which causes resulting string to not be escaped by Rails
  #       When this arg is set to false, that behavior is reverted here
  #       This is needed for few pages only, where double-rendering occurs, eg. recognition edit page, and approval / denial swals
  #   - whitelisting of :style attribute (disallowed for now)
  #       The only useful case for allowing this is when copy pasting formatted text into the editor
  #       But allowing this can sometimes cause the unintentional `font-size` style to be preserved, which causes formatting issues.
  #
  def sanitized_message(tags_to_exclude: [], html_safe: true, escape_before_sanitizing: false)
    return self.message if self.message.blank?

    allowed_tags, allowed_attributes = Recognition.allowed_html_tags_and_attributes(tags_to_exclude: tags_to_exclude)
    opts = { tags: allowed_tags, attributes: allowed_attributes}

    message = self.message
    message = CGI.escapeHTML(message) if escape_before_sanitizing
    message = sanitize(message, opts)
    message = message.to_str unless html_safe # back to String from ActiveSupport::SafeBuffer
    message
  end

  def input_format_html?
    self.input_format == 'html'
  end

  def input_format_text?
    self.input_format == 'text'
  end

  def consolidate_errors
    # normalize the associated errors into the recognition object
    self.user_recipients.each do |recipient|
      if recipient.errors.present?
        self.errors.add(:recipients, "^#{recipient.email}:  #{recipient.errors.full_messages.to_sentence}")
      end
    end
  end

  def self.create_custom(sender, recipients, badge, message, opts={}, company = nil)
    Recognition.new(
      sender: sender,
      recipients: recipients,
      sender_company: sender&.company || company,
      badge: badge,
      message: message
    ).tap do |r|
      r.assign_attributes(opts.slice(
        :is_private,
        :viewer, :viewer_description,
        :from_bulk,
        :skip_notifications, :skip_send_limits,
        :post_to_fb_workplace, :post_to_yammer_wall,
        :from_inbound_email_id, :input_format
      ))

      r.post_to_yammer_group_id = (opts[:post_to_yammer_group_id] || r.authoritative_company&.post_to_yammer_group_id) if r.post_to_yammer_wall == true
      r.bulk_imported_at = opts[:bulk_imported_at] if opts.has_key?(:bulk_imported_at) && r.from_bulk
      r.is_private = !!r.is_private

      if opts.has_key?(:soft_save) && opts[:soft_save]
        r.save
      else
        r.save!
      end
    end
  end

  # these are almost the same as default, except for a few tweaks
  # set additional attrs here if needed
  def self.allowed_html_tags_and_attributes(tags_to_exclude: [])
    default_attributes = Rails::Html::WhiteListSanitizer.allowed_attributes
    # for links
    custom_attributes = ['target']
    # disallow basic selector attrs that could targeted by application styles/scripts (id is already excluded by default)
    attrs_to_exclude = ['class']
    allowed_attributes = default_attributes + custom_attributes - attrs_to_exclude

    default_tags = Rails::Html::WhiteListSanitizer.allowed_tags
    allowed_tags = default_tags - tags_to_exclude

    [allowed_tags, allowed_attributes]
  end

  def is_publicly_viewable?
    self.is_public_to_world? && self.authoritative_company.allow_admin_dashboard?
  end

  # extract all the image urls in the recognition html message
  def message_image_urls
    return [] if message.blank?
    doc = Nokogiri::HTML(message)
    doc.xpath("//img").map{|el| el['src'] }
  end

  protected

  def after_create_async_service
    # pass relevant virtual attributes manually as a hash, as they are lost when retrieving from the database
    user_attrs_map = self.user_recipients.map{|u| [u.id, {skip_name_validation: u.skip_name_validation}]}
    user_recipient_attrs = Hash[ user_attrs_map ]
    delayed_async_service.call_after_create(user_recipient_attrs)
  end

  def after_save_async_service
    after_save_if_approved if status_changed_to_approved?
  end

  def after_commit_async_service
    delayed_async_service.send_notifications(post_to_yammer_group_id: self.post_to_yammer_group_id)
  end

  def publish_recognition_pending
    delayed_async_service.publish_recognition_pending
  end

  def after_save_if_approved
    delayed_async_service.update_counter_caches
  end

  # the deleted? check is especially required for specs
  def status_changed_to_approved_and_not_deleted?
    self.status_changed_to_approved? && !self.deleted?
  end

  def status_pending_and_not_deleted?
    self.pending_approval? && !self.deleted?
  end

  def delayed_async_service
    RecognitionAsyncService.new(self.id).delay(queue: 'priority')
  end

  def only_system_users_can_send_system_badges
    if badge and sender and (badge.system? and !sender.system_user?) and !self.is_instant?
      errors.add(:sender_name, I18n.t("activerecord.errors.models.recognition.badge_name_same_system_name"))
    end
  end

  def new_user_recipients_are_valid
    user_recipients.select(&:new_record?).reject(&:valid?).each do |ur|
      errors.add(:user_recipients, ur.errors.messages)
    end
  end

  def cannot_send_to_self
    # Condition: sender is a recipient, and sender is outside a team.
    if user_recipients.include?(sender) && recognition_recipients.detect{|rr| rr.user_id == sender.id && rr.team_id.blank?}.present?
      errors.add(:user_recipients, I18n.t("activerecord.errors.models.recognition.sender_and_recipient_are_same"))
      user_recipients.detect{|r| r == sender}.errors.add(:email, I18n.t('activerecord.errors.models.recognition.not_same_as_email'))
    end
  end

  def cannot_send_to_teams_that_have_only_self
    if @team_recipients.present?
      @team_recipients.select{|team| team.users == [sender]}.each do |team|
        errors.add(:recipients, I18n.t('activerecord.errors.models.recognition.check_team_does_not_have_only_sender', team_name: team.name))
      end
    end
  end

  # Note: Here we need to make sure that the sender wasn't also added individually (i.e. having nil team_id)
  #       This prevents the edge case where the recognition is still invalid but there is no error to show in frontend
  #       https://github.com/Recognize/recognize/issues/1948
  def exclude_sender_in_team_from_recognition_recipients
    sender_recipients = recognition_recipients.select {|rr| rr.user_id == sender&.id }
    if sender_recipients.any?{|rr| rr.team_id.present? } && sender_recipients.none?{|rr| rr.team_id.nil? }
      self.recognition_recipients = self.recognition_recipients.reject{|rr| rr.team_id.present? && rr.user_id == sender.id}
    end
  end

  def disallow_recognizing_disabled_user
    return if status_changing_to_denied?

    if user_recipients.detect{|x| x.email if (x&.network&.casecmp?(sender&.network) && x&.disabled? ) }
      if user_recipients.count == 1
        errors.add(:recipients, I18n.t('activerecord.errors.models.recognition.disallow_recognizing_disabled_account'))
      else
        emails = user_recipients.select{|x| x&.network&.casecmp?(sender&.network) && x.disabled? }.map(&:email)
        emails.each do |email|
          errors.add(:recipients, I18n.t('activerecord.errors.models.recognition.disallow_recognizing_disabled_account_email', email: email))
        end
      end
    end
  end

  def disallow_recognition_from_disabled_user
    return unless self.from_bulk?
    return if self.is_anniversary?

    errors.add(:base, I18n.t('activerecord.errors.models.recognition.sender_is_disabled')) if self.sender&.disabled?
  end

  def privacy_and_social_sharing
    if self.is_private && self.social_sharing_enabled?
      errors.add(:is_private, I18n.t('activerecord.errors.models.recognition.privacy_and_social_sharing_not_valid'))
    end
  end

  # In rare cases, HTML content can be extremely long, exceeding database column limit (eg. with data URLs)
  # Reject such cases explicitly instead of failing hard with server error
  # Note: The db limit is currently 65535 bytes (default for text)
  def message_size_is_within_limit
    if message && message.bytesize > 50_000
      errors.add(:message, I18n.t('activerecord.errors.models.recognition.message_too_long'))
    end
  end

  def social_sharing_enabled?
    self.post_to_yammer_wall.present? || self.post_to_fb_workplace.present?
  end

  def ensure_company
    self.sender_company_id ||= self.sender&.company_id
    self.authoritative_company_id ||= self.authoritative_company&.id
  end

  # Note: The 'rr.user.company_id' fallback for recipient_company_id is borrowed from an after_create method :ensure_recipients_have_company_id_set
  def set_cross_company_attribute
    return true unless self.sender_company_id

    if self.badge.present? && self.is_anniversary?
      self.is_cross_company = false
    else
      self.is_cross_company = recognition_recipients.any? do |rr|
        recipient_company_id = rr.recipient_company_id || rr.user.company_id
        recipient_company_id != self.sender_company_id
      end
    end
    true # never halt the callback chain
  end

  def set_message_plain
    if self.new_record?
      return if self.message.blank? || self.message_plain
    elsif self.message.blank?
      return self.message_plain = nil
    end

    # add space inside p tags so words separated by new lines don't end up sticking to each other
    plain_message = self.message.gsub(%r{</p>}, ' \0')
    # actual plain-text conversion. This is being done regardless of wysiwyg enabled setting to be safe
    plain_message = strip_tags(plain_message)
    # remove extra spaces added during regex replace above, and possible extra whitespace characters
    plain_message = plain_message.squish
    self.message_plain = plain_message
  end

  def convert_recipient_emails_to_user
    if self.recipient_emails.kind_of?(Enumerable)
      set = []
      self.recipient_emails.each do |e|
        if e.index("@")
          # If email is in multiple accounts, use the one identified by sender's network
          email_users = User.where(email: e)

          # try to match on authoritative company's domain, or user first one found(if there are any)
          u = email_users.detect{|u| u.network.casecmp?(self.authoritative_company.try(:domain))} || email_users.first

          # if still none, initialize
          unless u
            u = User.new(email: e)
          end

          u.skip_name_validation = true
          u.set_status!(:invited_from_recognition) unless u.persisted? && ( u.active? || (u.disabled? && u.network.casecmp?(self.sender.try(:network))))
          set << u
        end
      end
      # self.user_recipients ||= []
      # self.user_recipients += set

      set.each do |user|
        self.add_recipient(user)
      end
    end
  end

  def ensure_skipping_user_name_validation
    self.user_recipients.each do |r|
      r.skip_name_validation = true
    end
  end

  def strip_placeholder
    if self.message == I18n.t("recognition_new.reason_for_the_recognition")
      self.message = ""
    end
  end

  # @see the relevant spec for a list of sample cases covered
  #      spec/models/recognition_spec.rb (search method name)
  def strip_empty_tags_around_html_message
    if self.message.present? && self.input_format_html?
      # matches empty <p> or <br> or <p> with <br> or any combination thereof, with consideration for whitespaces
      empty_tags_rx_str = '(\s*<br>\s*|<p>(<br>|</?p>|\s*)*</p>\s*)+'

      self.message = self.message
                       .gsub(/\A#{empty_tags_rx_str}/, '')   # at the beginning
                       .gsub(/#{empty_tags_rx_str}\z/, '')   # at the end
                       .strip
    end
  end

  def strip_duplicate_recipients
    # Its possible we could be recognizing multiple new users by email
    # In which case, they won't have ids
    # If we uniq against nil ids, we might remove ones erroneously
    if recognition_recipients.present?
      with_ids, without_ids = self.recognition_recipients.partition{|rr| rr.user_id.present? }

      set = []
      set += with_ids.uniq{|rr| "#{rr.user_id}-#{rr.team_id}"} if with_ids.present?
      set += without_ids.uniq{|rr| rr.user.try(:email)} if without_ids.present?

      self.recognition_recipients = set
    end
  end

  #Here are the possibilities:
  #1. The recipient input is left completely blank
  #2. A proper user is selected from the list
  #3. A user types a valid email
  #4. A user types an invalid email
  def check_recipient_or_email
    has_error = false

    unless user_recipients.present?
      if recipient_emails.present?
        recipient_emails.each do |e|
          errors.add(:user_recipients, I18n.t("activerecord.errors.models.recognition.not_properly_formatted", e: e)) unless e.match(Constants::EMAIL_REGEX)
        end
      else
        errors.add(:sender_name, I18n.t('activerecord.errors.models.recognition.recipient_or_email'))
      end
    end

  end

  def check_teams_have_users
    team_ids = (@team_recipients || []).map(&:id)
    team_ids_without_users = team_ids - UserTeam.where(team_id: team_ids).pluck(:team_id).uniq
    if team_ids_without_users.present?
      errors.add(:recipients, I18n.t('activerecord.errors.models.recognition.check_teams_have_users'))
    end
  end

  def sender_has_permission_to_send_badge
    if self.badge.present? &&
        self.badge.roles_with_permission(:send).present? &&
        !self.sender&.sendable_badges.include?(self.badge)
      errors.add(:base, I18n.t("activerecord.errors.models.recognition.sender_doesnt_have_permission_to_send_badge"))
    end
  end

  def can_send_achievement_badge
    if badge.present? && badge.is_achievement? && user_recipients.present?

      if user_recipients.length > 1 || user_recipients.any?{|r| !r.kind_of?(User)}
        errors.add(:recipients,  I18n.t('activerecord.errors.models.recognition.can_send_achievement_badge_single_user'))

      else
        start_time = badge.interval.start
        recipient = user_recipients.first
        achievement_recognitions = recipient.received_recognitions.approved.where("created_at >= ?", start_time).where(badge_id: badge.id)
        if skip_send_limits.blank? && (achievement_recognitions.size >= badge.achievement_frequency) && !self.denied?
          errors.add(:recipients, I18n.t('activerecord.errors.models.recognition.can_send_achievement_badge_max_amt' ,badge: badge.short_name, interval: reset_interval_noun(badge.interval)))
        end
      end

    end
  end

  def tags_are_present
    return if self.tags.present?

    errors.add(:tags, I18n.t("activerecord.errors.models.recognition.attributes.tags.blank",
                             tag_label: authoritative_company.custom_labels.recognition_tags_label.singularize(I18n.locale)))
  end

  def is_within_sending_limits
    # Never check send limits when its an anniversary badge
    return true if self.is_anniversary?
    return false unless sender
    return true if self.sender.system_user? # never check system user

    # 1. check user has not exhausted total number of recognitions(global limit)
    # 2. check if badge has explicit limit and user has not exhausted recognitions for that badge
    # 3. If no explicit badge limit, check against default limit
    if authoritative_company&.recognition_limit_frequency.present? && authoritative_company.recognition_limit_frequency.to_i.positive?
      authoritative_company.recognition_limit_scope.recognition? ?
        is_within_company_sending_limits :
        is_within_company_sending_limits_by_user
    end

    unless self.has_send_limit_error
      if badge.present? && badge.sending_frequency.present? && badge.sending_frequency.to_i.positive?
        badge.sending_limit_scope.recognition? ?
          is_within_badge_sending_limits :
          is_within_badge_sending_limits_by_user

      elsif authoritative_company&.default_recognition_limit_frequency.present? && authoritative_company.default_recognition_limit_frequency.to_i.positive?
        authoritative_company.default_recognition_limit_scope.recognition? ?
          is_within_default_badge_sending_limits :
          is_within_default_badge_sending_limits_by_user
      end
    end

  end

  def is_within_badge_sending_limits
    start_time = badge.sending_interval.start
    interval_sent_recognitions_count = sender.sent_recognitions.not_denied.where("created_at >= ?", start_time).where(badge_id: badge.id).size
    if interval_sent_recognitions_count >= badge.sending_frequency
      self.has_send_limit_error = true
      errors.add(:recipients,
        I18n.t('activerecord.errors.models.recognition.is_within_badge_sending_limits',
        frequency: I18n.t('dict.frequency.times', count: badge.sending_frequency),
        interval: reset_interval_noun(badge.sending_interval).downcase))
    end
  end

  def is_within_badge_sending_limits_by_user
    start_time = badge.sending_interval.start
    interval_sent_users_count = sender.sent_recognitions.not_denied.where("created_at >= ?", start_time).where(badge_id: badge.id).map(&:user_recipients).flatten.size
    if (interval_sent_users_count + self.user_recipients.length) > badge.sending_frequency
      self.has_send_limit_error = true
      errors.add(:recipients,
        I18n.t('activerecord.errors.models.recognition.is_within_badge_sending_limits_for_users',
        added_recipients: self.user_recipients.length,
        frequency: I18n.t('dict.frequency.people', count: badge.sending_frequency),
        interval: reset_interval_noun(badge.sending_interval).downcase))
    end
  end

  def is_within_default_badge_sending_limits
    start_time = authoritative_company.default_recognition_limit_interval.start
    interval_sent_recognitions_count = sender.sent_recognitions.not_denied.where("created_at >= ?", start_time).size
    if interval_sent_recognitions_count >= authoritative_company.default_recognition_limit_frequency
      self.has_send_limit_error = true
      errors.add(:recipients,
        I18n.t('activerecord.errors.models.recognition.is_within_default_badge_sending_limits',
        frequency: I18n.t('dict.frequency.badges', count: authoritative_company.default_recognition_limit_frequency),
        interval: reset_interval_noun(authoritative_company.default_recognition_limit_interval).downcase))
    end
  end

  def is_within_default_badge_sending_limits_by_user
    start_time = authoritative_company.default_recognition_limit_interval.start
    interval_sent_users_count = sender.sent_recognitions.not_denied.where("created_at >= ?", start_time).map(&:user_recipients).flatten.size
    if (interval_sent_users_count + self.user_recipients.length) > authoritative_company.default_recognition_limit_frequency
      self.has_send_limit_error = true
      errors.add(:recipients,
        I18n.t('activerecord.errors.models.recognition.is_within_default_badge_sending_limits_for_users',
        frequency: I18n.t('dict.frequency.people', count: authoritative_company.default_recognition_limit_frequency),
        interval: reset_interval_noun(authoritative_company.default_recognition_limit_interval).downcase))
    end
  end

  def is_within_company_sending_limits
    start_time = authoritative_company.recognition_limit_interval.start
    interval_sent_recognitions_count = sender.sent_recognitions.not_denied.where("created_at >= ?", start_time).size
    if interval_sent_recognitions_count >= authoritative_company.recognition_limit_frequency
      self.has_send_limit_error = true
      errors.add(:recipients,
        I18n.t('activerecord.errors.models.recognition.is_within_company_sending_limits',
        frequency:  I18n.t('dict.frequency.badges', count: authoritative_company.recognition_limit_frequency),
        interval: reset_interval_noun(authoritative_company.recognition_limit_interval).downcase))
    end
  end

  def is_within_company_sending_limits_by_user
    start_time = authoritative_company.recognition_limit_interval.start
    interval_sent_users_count = sender.sent_recognitions.not_denied.where("created_at >= ?", start_time).map(&:user_recipients).flatten.size

    if (interval_sent_users_count + self.user_recipients.length) > authoritative_company.recognition_limit_frequency
      self.has_send_limit_error = true
      errors.add(:recipients,
        I18n.t('activerecord.errors.models.recognition.is_within_company_sending_limits_for_users',
        frequency: I18n.t('dict.frequency.people', count: authoritative_company.recognition_limit_frequency),
        interval: reset_interval_noun(authoritative_company.recognition_limit_interval).downcase))
    end
  end

  def generate_slug
    slug = (self.id+self.created_at.to_f.to_s.gsub(".", '').to_i).to_s(32)
    # Bypasses the validation, but doesn't pollute the after_create callback
    # Previously, `update_attribute` was used, which triggered `after_update` callbacks.
    self.update_column(:slug, slug)
  end

  # FIXME: had to hack up this method because TeachFirst was blocked from sending recognitions
  #              because they added a ton of groups in the microsoft_graph_sync_groups field
  #              which delayed_job barfed on. So moving the whole method to a smaller DJ call.
  #
  def update_user_recognitions_counter_cache
    Recognition.delay(queue: 'priority_caching').delayed_update_user_recognitions_counter_cache(self.id)
  end

  def self.delayed_update_user_recognitions_counter_cache(recognition_id)
    r = Recognition.with_deleted.find(recognition_id)
    Company.unscoped do
      r.authoritative_company.refresh_all_counter_caches!

      set = r.recognition_recipients.with_deleted.map(&:recipient_company_id).uniq.each do |c_id|
        next unless c_id
        c = Company.find(c_id)
        c.refresh_all_counter_caches! if c_id
      end
    end
  end

  def set_affected_participants
    self.affected_participant_ids = self.participants.map(&:id)
  end

  # FIXME: not sure if this is necessary as its handled
  #        by Points::ChangeObserver#destroy
  def update_participant_point_totals!
    self.affected_participant_ids.each do |id|
      User.find(id).delay(queue: 'points').update_all_points! if User.exists?(id)
    end
  end

  def should_require_message
    authoritative_company&.message_is_required? && message.blank?
  end

  def should_require_tags?
    return false if self.is_anniversary? || self.is_ambassador? || self.from_bulk?

    !!authoritative_company&.requires_recognition_tags?
  end
  # NOTE: the api allows you to specify a string badge name or id as the badge
  #       The parameter is passed as a string to #badge= which, if its detected as a string,
  #       gets assigned to #badge_name. We need to convert this #badge_name to a badge
  #       in a before_validation so other validations that require it like send limit validations
  #       can have it.
  #
  def convert_badge_name_to_badge
    return if self.badge.kind_of?(Badge) || self.badge_name.blank?

    self.badge = BadgeFinder.find(self.authoritative_company, self.badge_name)
  end

  # NOTE: the idea behind this validation is that we show suggested badge names only when #badge_name
  #       has been specified. In other words, suggest badge names when it comes in from api because clients
  #       such as Slack permit free form typing of Badge name
  def badge_name_is_valid
    if badge_name.present?
      unless self.badge.kind_of?(Badge)
        badge_names = self.authoritative_company.company_badges.map(&:short_name).to_sentence(two_words_connector: ' or ', last_word_connector: ' or ')
        errors.add(:badge, I18n.t('activerecord.errors.models.recognition.attributes.badge_id.invalid_name', badge_names: badge_names))
      end
    end
  end

  def recipients_are_within_org
    return if sender && sender.system_user?
    return if from_bulk

    # check recipients are in sender's company
    if authoritative_company&.limit_sending_to_intracompany_only?
      existing_emails = authoritative_company.users.map(&:email)
      recipient_emails = self.user_recipients.map(&:email)
      # have to check recipient email is in set of sender's network
      # senders company can have users who have mixed domains
      if (recipient_emails - existing_emails).present? # if recipient email not in existing email set
        errors.add(:recipients,
          I18n.t('activerecord.errors.models.recognition.recipients_outside_of_org'))
      end
    else
      # check sender is in recipients companies
      user_recipient_company_ids = self.user_recipients.map(&:company_id).uniq
      companies_that_restrict_intra_company_recognitions = Company.where(id: user_recipient_company_ids, limit_sending_to_intracompany_only: true)

      if companies_that_restrict_intra_company_recognitions.any? {|c| c.id != authoritative_company.id }
        errors.add(:recipients,
          I18n.t('activerecord.errors.models.recognition.sender_outside_recipient_org'))
      end
    end

  end

  def no_team_recipients_when_teams_disabled
    if sender && !self.authoritative_company.allow_teams? && @team_recipients.present?
      errors.add(:base, I18n.t('activerecord.errors.models.recognition.teams_are_disabled'))
    end
  end

  def self.status_id_by_name(state_name)
    ApprovalWorkflow::States.find_by_name(state_name).id
  end

  def manager_ids
    immediate_manager_ids + manager_of_manager_ids
  end

  def manager_of_manager_ids
    user_recipients_with_managers.map do |user|
      user.second_level_manager.try(:id)
    end.flatten.compact
  end

  def immediate_manager_ids
    user_recipients_with_managers.map(&:manager_id)
  end

  def user_recipients_with_managers
    User.includes(company: :settings).includes(manager: :manager).where(id: self.user_recipients.map(&:id)).includes(:manager).joins(:manager)
  end

  def set_approved_at
    return if self.requires_approval

    self.approved_at = Time.current
  end

  private

  def deduce_post_to_yammer_group_id
    self.post_to_yammer_group_id = begin
      if (company_set_post_to_yammer_group_id = self.sender&.company&.post_to_yammer_group_id).present?
        company_set_post_to_yammer_group_id
      elsif (yammer_all_company_group = self.sender&.yammer_all_company_group).present? && yammer_all_company_group.restricted_posting == false
        # Last resort
        yammer_all_company_group.id
      else
        nil
      end
    end
  end

  def anniversary_recognition_custom_sender_name
    @anniversary_recognition_custom_sender_name ||= self.authoritative_company.settings.anniversary_recognition_custom_sender_name
  end
end
