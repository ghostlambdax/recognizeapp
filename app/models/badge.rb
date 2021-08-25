# reset badge images for company:
# prefix = "/Users/pete/work/recognize/app/assets/images/badges/200/"
# c.company_badges.each{|b| b.image = File.open(prefix+b.short_name.downcase+".png");b.save;}
#
require_dependency File.join(Rails.root, 'db/anniversary_badges')

class Badge < ApplicationRecord
  include Authz::PermissionsHelper

  acts_as_paranoid
  mount_uploader :image, BadgeUploader

  enum approval_strategy: [:any_manager], _suffix: true

  USER_BADGES = [:thumbs_up, :boss, :brilliant, :caring, :coffee_maker, :comedian, :cooperative, :creative, :detailed, :determined, :efficient, :friend,
    :fun, :hacker, :honorable, :innovative, :leader, :listener, :on_track, :organized, :passionate, :peace_maker,
    :popular, :powerful, :problem_solver, :provider, :punctual, :responsive, :skilled, :speaker, :speedy]

  SYSTEM_BADGES = [:on_fire, :new_user, :ambassador]
  SET = USER_BADGES+SYSTEM_BADGES
  INSTANT = [:thumbs_up]

  NOUNS = [:boss, :comedian, :friend, :hacker, :leader, :listener, :new_user, :problem_solver, :provider, :speaker]
  ADJECTIVES = SET-NOUNS

  #MAP TAGS TO BADGES
  TAG_MAP = {
    fun: [:coffee_maker, :comedian, :fun],
    encouraging: [:boss, :brilliant, :caring, :cooperative, :creative, :friend, :honorable, :thumbs_up],
    productivity: [:boss, :creative, :detailed, :determined, :efficient, :honorable]
  }

  #MAP BADGES TO TAGS
  TAG_INVERSE_MAP = TAG_MAP.inject({}){|map, tag_and_badges|
    tag = tag_and_badges[0]
    badge_array = tag_and_badges[1]
    badge_array.each{|badge| map[badge] ||= []; map[badge] << tag}
    map
  }

  # Override the default names
  # this is used by the badges factory
  # NOTE: if overriding the default name
  #       be sure to include change in a
  #       migration
  NAME_OVERRIDES = {
  }

  # if this changes, update in db/anniversary_badges, need to do this way to avoid circular dependency
  BIRTHDAY_TEMPLATE_ID = "00_birthday"

  attr_accessor :original_id

  belongs_to :company, optional: true
  has_many :recognitions
  has_many :campaigns

  serialize :point_values, Array

  before_validation :format_names
  before_validation :massage_point_values
  before_destroy :only_destroy_if_custom_badge

  validates :anniversary_message, presence: true, if: :is_anniversary?
  validates :short_name,  presence: true
  validate :image_is_present
  # validates :name, uniqueness: {scope: [:company_id, :deleted_at]}
  validates :short_name, uniqueness: {scope: [:company_id, :deleted_at], case_sensitive: false}
  validate :can_set_as_achievement
  validate :cannot_set_instant_if_achievement
  validate :is_nomination_is_not_nil
  validate :prevent_nomination_change_once_nominations_are_sent
  validate :cannot_force_privacy_if_company_disallows_privacy
  validate :point_values_must_be_integer
  validate :approver_present_and_valid, if: :requires_approval?
  validate :cannot_set_requires_approval_if_is_nomination, if: :requires_approval?

  validates :achievement_interval_id, inclusion: {in: Interval::RESET_INTERVALS.keys}
  validates :achievement_frequency, numericality: { only_integer: true, greater_than: 0}
  validates :sort_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: false

  scope :system_badges, -> { where(name: SYSTEM_BADGES) }
  scope :user_badges, -> { where(name: USER_BADGES, company_id: nil).not_disabled }
  scope :all_user_badges, -> { where(name: USER_BADGES, company_id: nil) }
  scope :unrestricted, -> { where(restricted: false) }
  scope :noncompany, -> { where(company_id: nil) }
  scope :achievements, -> { where(is_achievement: true) }
  scope :admin, -> { where(restricted: true) }
  scope :normal, -> { where(restricted: false, is_achievement: false) }
  scope :disabled, -> { where.not(disabled_at: nil)}
  scope :not_disabled, -> { where(disabled_at: nil)}
  scope :enabled, -> { not_disabled.non_anniversary }
  scope :nominations, -> { where(is_nomination: true) }
  scope :recognitions, -> { where(is_nomination: false, is_anniversary: false) }
  scope :anniversary, ->{ where(is_anniversary: true) }
  scope :non_anniversary, ->{ where(is_anniversary: false)}
  scope :non_nominations, ->{ where(is_nomination: false)}
  scope :without_sending_limit, ->{ where(sending_frequency: nil) }
  scope :quick_nominations, ->{ nominations.where(is_quick_nomination: true) }
  scope :show_in_badge_list, ->{ where(show_in_badge_list: true) }
  scope :with_forced_privacy, ->{ where(force_private_recognition: true) }
  scope :sort_with_order, -> { order(sort_order: :asc, short_name: :asc) }

  @@badges = {}
  SET.each do |b|
    define_singleton_method(b) { @@badges[b] ||= where(name: b).first }
    define_method("#{b}?") { name == b }
  end

  def sending_limit_scope
    Recognition::LimitScope.find(sending_limit_scope_id || Recognition::LimitScope::SCOPE_LIMIT_BY_USERS)
  end

  def self.anniversary_templates(company)
    ANNIVERSARY_BADGES.keys.map do |template_id|
      AnniversaryBadgeManager.template_for(template_id, company)
    end
  end

  def self.total_possible_achievement_count(user)
    count = user.company.company_badges.achievements.inject(0) do |total_count, badge|
      total_count += badge.achievement_frequency
    end
    return count
  end

  def self.add_custom!(company_id, name, image_url, opts={})
    b = Badge.new(opts)
    b.name = name.downcase.gsub(" ",'_')
    b.short_name = name
    b.company_id = company_id
    b.remote_image_url = image_url
    b.points = opts[:points] || 10
    b.save!
    return b
  end

  def nomination_award_limit_interval
    Interval.new(nomination_award_limit_interval_id)
  end

  def points
    read_attribute(:points) || 10
  end

  def disable!
    touch(:disabled_at)
  end

  def disabled?
    disabled_at.present?
  end

  def recognition?
    !is_nomination? && !is_anniversary?
  end

  def nomination?
    is_nomination?
  end

  #virtual attribute that is converse of disabled_at, allows enabled checkboxes for badges, rather than delete btn
  def is_enabled
    @is_enabled.nil? ? disabled? : @is_enabled
  end

  def is_enabled=(val)
    @is_enabled = val
    if val === false || val === "0" # a bit hacky
      self.disabled_at = Time.now
    else
      self.disabled_at = nil
    end
  end

  EXCLUDE_ATTRIBUTES_FROM_CLONE = ["id", "image", "is_anniversary", "created_at", "updated_at",
    "company_id", "deleted_at", "nomination_award_limit_interval_id", "is_quick_nomination"]
  def clone_to_custom
    # raise "You may not clone a custom badge" if self.company_id.present? && !self.company.in_family?


    custom_name = self.short_name.downcase.gsub(" ",'_')
    custom_name = "#{custom_name}_#{Time.now.to_f.to_s.gsub('.', '')}"

    new_attributes = self.attributes.clone.except(*EXCLUDE_ATTRIBUTES_FROM_CLONE)
    b = Badge.new(new_attributes)
    b.name = custom_name
    b.deleted_at = self.deleted_at
    b.original_id = self.id

    # b.image = self.local_file
    # Need to account when using different storage providers(dev vs prod)
    begin
      if self.image.url.start_with?("http")
        b.remote_image_url = self.image.url
      elsif self.image.url.start_with?("/uploads")
        b.image = File.open(File.join(Rails.root, "public", self.image.url))
      elsif match = self.image.url.match(Regexp.quote("//#{Recognize::Application.config.host}"))
        path = self.image.url.gsub(match.regexp, '')
        b.image = File.open(File.join(Rails.root, "public", path))
      else
        b.image = self.local_file
      end
    rescue => e
      Rails.logger.warn "Could not add image for cloned badge(#{self.company.try(:domain)}): #{self.inspect} - #{e}"
    end

    return b
  end

  def custom?
    self.company_id.present?
  end

  def instant?
    is_instant?
  end

  def self.cached(id)
    return nil unless id.present?
    Rails.cache.fetch("Badges/#{id}") do
      self.find(id)
    end
  end

  # FIXME: this should be renamed #achievement_interval
  def interval
    @interval ||= Interval.new(achievement_interval_id)
  end

  def sending_interval
    @sending_interval ||= begin
      # # if sending frequency is blank, default to company's interval
      # if self.company && sending_frequency.blank?
      #   Interval.new(self.company.reset_interval)
      # else
        Interval.new(sending_interval_id)
      # end
    end
  end

  def sending_frequency_with_interval
    sending_interval.prefixed_adverb(prefix: sending_frequency)
  end

  def self.update_cache!(id)
    Rails.cache.write("Badges/#{id}", self.find(id) )
  end

  def self.random_from_instant(company=nil)
    if company && company.custom_badges_enabled?
      set = company.badges.enabled
      instant_badges = set.select{|badge| badge.instant? }
      if instant_badges.present?
        instant_badges[rand(instant_badges.length)]
      else
        # try to find the thumbs up badge
        # otherwise(if its disabled), just use the first enabled badge
        set.detect{|b| b.name.to_s.match(/thumbs_up/)} || set.first

      end
    else
      Badge.send(INSTANT[rand(INSTANT.length)])
    end
  end

  def self.system_badge_ids
    @@system_badge_ids ||= Badge.system_badges.pluck(:id)
  end

  def self.top_badges(opts={})
    opts[:limit] ||= 5
    set = Recognition.where("badge_id NOT IN (?)", Badge.system_badge_ids).reorder('').group(:badge_id).order("count_badge_id desc").limit(opts[:limit]).count(:badge_id)
    set = set.inject({}){|hash, data| hash[data[0]] = {badge: Badge.cached(data[0]), count: data[1]}; hash}
    return set
  end

  def self.top_badges_for_company(company, opts={})
    # opts[:limit] ||= 5
    # set = Recognition.for_company(company).where("badge_id NOT IN (?)", Badge.system_badge_ids).reorder('').group(:badge_id).order("count_badge_id desc").limit(opts[:limit]).count(:badge_id)
    # set = set.inject({}){|hash, data| hash[data[0]] = {badge: Badge.cached(data[0]), count: data[1]}; hash}
    return self.top_badges_for_companies(company.id, opts)

  end

  def self.top_badges_for_companies(company_ids, opts={})
    opts[:limit] ||= 5

    scope = Recognition.approved
    scope = if opts[:recognition_ids].present?
              scope.where(id: opts[:recognition_ids])
            else
              scope.where(sender_company_id: company_ids)
            end

    if opts[:since]
      # scope = scope.select{|r| r.created_at >= opts[:since]}
      scope = scope.where("created_at >= ?", opts[:since])
    end

    set = scope.where("badge_id NOT IN (?)", Badge.system_badge_ids).reorder('').group(:badge_id).order("count_badge_id desc").limit(opts[:limit]).count(:badge_id)
    set = set.inject({}){|hash, data| hash[data[0]] = {badge: Badge.find(data[0]), count: data[1]}; hash}
    return set

  end

  def self.add_to_system!(name)
    if SET.include?(name.to_sym)
      #TODO: check all the requirements have been met: image, style, etc...
      FactoryBot.create("#{name}_badge")
    else
      raise "#{name} is not a valid badge name!  Please check app/models/badge.rb"
    end
  end

  def tags
    TAG_INVERSE_MAP[self.name]
  end

  def name
    (n = read_attribute(:name)) && n.to_sym
  end

  def system?
    @is_system ||= SYSTEM_BADGES.include?(self.name)
  end

  def user?
    !system?
  end

  def birthday?
    self.anniversary_template_id == self.class::BIRTHDAY_TEMPLATE_ID
  end

  def image_for_size(size)
    case size
    when 50
      image.small_thumb
    when 100
      image.thumb
    when 200
      image.large_thumb
    else
      image
    end
  end

  # this is really only useful when migrating core badges to the new model with company id
  # where badge images are stored in /uploads(either in public or via cdn)
  def local_path(size=200)
    "/assets/images/badges/200/#{self.name.to_s.gsub('_','-')}.png"
  end

  def local_file(size=200)
    File.open(File.join(Rails.root, "app", self.local_path))
  end

  def image_url(size=200)
    image_for_size(size).url
  end

  def permalink(size=200, protocol=Recognize::Application.config.web_protocol)
    # NOTE: action_controller.asset_host MUST be set to a fqdn, eg. http://localhost:3000/
    # url will have path to cdn image in production
    if Rails.env.production?
      return image_url(size) #if Rails.env.production?
    elsif Rails.env.test?
      return "/images/" + (image_url(size) || "")
    else
      return "https://#{Rails.application.config.host}#{image_url(size)}"
    end
  end

  def in_sentence
    NOUNS.include?(self.name) ? "a #{self.short_name.downcase}" : self.short_name.downcase
  end

  def can_destroy?
    recognitions.size == 0
  end

  def points_are_redeemable?
    # FIXME: fill out with customizable database attribute or other logic
    !system?
  end

  def nominations_have_been_sent?
    self.campaigns.present?
  end

  def recognitions_have_been_sent?
    self.recognitions.present?
  end

  BudgetCalculationException = Class.new(Exception)
  def possible_points_per_reset_interval
    if self.sending_limit_scope.recognition?
      raise BudgetCalculationException, "Cannot calculate points when badge is set to limit by recognition"
    else
      possible_points_per_reset_interval_for_user_send_limit_scope
    end
  end

  def possible_points_per_reset_interval_for_user_send_limit_scope
    # NOTE this does not support sending limit by users(one off feature for seegrid)
    if self.sending_frequency.present? && self.sending_frequency.to_i > 0
      company_interval = Interval.new(self.company.reset_interval)
      factor = Interval.conversion_factor(company_interval, self.sending_interval)

      if factor > 0
        possible_points = (self.sending_frequency * self.points) * factor
      else
        possible_points = (self.sending_frequency * self.points) / factor.abs # Integer division ok here
      end

      user_count = self.sendable_user_count
      possible_points *= user_count

    else
      possible_points = Float::INFINITY
    end

    return possible_points
  end

  def sendable_user_count
    roles = self.roles_with_permission(:send)
    if roles.present?
      user_count = self.company.get_user_ids_by_company_role_ids(roles.map(&:id)).size
    else
      user_count = self.company.users.active.size
    end
    return user_count
  end

  def self.roles_that_can_approve_badge_that_requires_approval
    [Role.company_admin, Role.manager]
  end

  def self.attributes_for_json
    @attributes_for_json = self.column_names + [:permalink]
  end

private

  # The relevant point_values params coming in from controller are strings. Convert them to integers, if possible.
  def massage_point_values
    return unless point_values_changed?
    return if point_values.all? { |value| value.is_a?(Integer) }

    point_values.map! do |value|
      (value.is_a?(String) && value.is_i?) ? value.to_i : value
    end
  end

  def point_values_must_be_integer
    return unless point_values_changed?
    return if point_values.all? { |value| value.is_a?(Integer) }

    errors.add(:point_values, "must be an Integer") unless point_values.all? {|value| value.is_a?(Integer)}
  end

  def create_instance_interrogator!(m)
    method_name = m.to_s
    if match = method_name.match(/(.*)\?$/)
      if @@badges[match[1]]
        Rails.logger.debug "defining Badge.#{match[1]}.#{method_name}"

        self.class.send(:define_method,method_name) do
          self.name.to_sym == match[1].to_sym
        end

        return method(method_name)

      #@@badges should never be empty - it should be bootstrapped
      elsif @@badges.empty? and !Rails.env.production?
        #HACK!
        #for some reason we're losing the class instance variable in development mode
        #so try to recreate the accessors
        Rails.logger.warn "lost @@badges...attempting to recreate(#{method_name})"
        Badge.all.each {|b| Badge.send(b.name)}
        raise "Could not fix problem recreating accessors(#{method_name})" if @@badges.empty? and Badge.count > 0

        self.class.send(:define_method,method_name) do
          self.name.to_sym == match[1].to_sym
        end

        return method(method_name)
      end
    end
  end

  #some meta-syntactic sugar to allow lookups by badge name
  #eg Badge.new_user, Badge.powerful
  #this could also be explicitly defined by using "scope"
  #but scopes always return an array, so it wouldn't be as nice
  #as you'd have to do Badge.powerful.first
  #this also caches the lookup in a class variable hash
  @@badges = {}
  def self.create_badge_accessor!(method_name)
    Rails.logger.debug "inside create badge accessor: #{method_name}"

    #prevent infinite recursion
    unless method_name == :find_by_name

      #lookup if there is a badge with the method name
      badge_name = method_name.to_s.underscore
      badge = self.find_by_name(badge_name)

      if badge
        @@badges[badge_name] = badge
        Rails.logger.debug "defining Badge.#{badge_name}"

        (class << self; self; end).send(:define_method, badge_name) do
          @@badges[badge_name]
        end

        return method(method_name)
      end

    end
  end

  def self._reload_badges!
    @@badges = {}
    eigen = (class << Badge;self;end)
    Badge.all.each{|b|
      if eigen.method_defined?(b.name.to_sym)
        # puts "removing #{b.name}"
        eigen.send(:remove_method, b.name.to_sym)
      end
      # puts "caching: Badge.#{b.name} and Badge##{b.name}?"
      Badge.send(b.name).send("#{b.name}?")
    }
  end

  # For custom badges, user will input the short name, so we need to format
  # the name and long names
  def format_names
    self.name = self.short_name.strip.downcase.underscore.gsub(" ", '_') unless self.short_name.blank? or self.name.present?
    self.short_name = self.short_name.strip if self.short_name.present?
  end

  def only_destroy_if_custom_badge
    errors.add :base, "You may not destroy a non custom badge" unless company_id.present?
    throw :abort unless errors.blank?
  end

  def approver_present_and_valid
    return unless self.requires_approval?

    if approver.blank?
      errors.add(:approver, "must be present")
    else
      approver_is_a_whitelisted_role = begin
        self.class.roles_that_can_approve_badge_that_requires_approval.map(&:id).include?(approver)
      end
      errors.add(:approver, "is invalid") unless approver_is_a_whitelisted_role
    end
  end

  def image_is_present
    errors.add(:image, "must be present") if self.image.file.blank? && !self.disabled? && !(Rails.env.test? || (Rails.env.development? && self.id.present?))
  end

  def can_set_as_achievement
    if(is_achievement? && custom? && !company.allow_achievements?)
      errors.add(:is_achievement, "is an Enterprise feature. What are you trying do here? Come on! Give us a call we\'ll make it right.")
    end
  end

  def cannot_set_instant_if_achievement
    if(is_achievement? && is_instant?)
      errors.add(:is_instant, "is not something you are going to want for achievements, for pete\'s sake.")
    end
  end

  def cannot_set_requires_approval_if_is_nomination
    return unless is_nomination? && requires_approval?

    errors.add(:is_nomination, "can not be set to require approval.")
  end

  def is_nomination_is_not_nil
    if self.is_nomination.nil?
      errors.add(:is_nomination, "may not be nil")
    end
  end

  def prevent_nomination_change_once_nominations_are_sent
    if changes["is_nomination"] == [true, false]
      if self.nominations_have_been_sent?
        errors.add(:is_nomination, "may not be turned off for this badge once a nomination has been sent")
      end
    elsif changes["is_nomination"] == [false, true]
      if self.recognitions_have_been_sent?
        errors.add(:is_nomination, "may not be turned on for this badge once recognitions have been sent")
      end
    end
  end

  # This should only be encountered in edge cases (since the relevant checkbox is hidden in this case)
  def cannot_force_privacy_if_company_disallows_privacy
    if self.force_private_recognition? && company&.allows_private? == false
      errors.add(:base, "Private recognitions must first be enabled before it can be forced.")
    end
  end

end
