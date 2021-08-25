class Team < ApplicationRecord
  include Points::Calculator
  include HashIdConcern
  extend HashIdConcern::Finder

  acts_as_paranoid

  has_many :user_teams, :dependent => :destroy
  has_many :users, :through => :user_teams
  has_many :team_managers, dependent: :destroy, inverse_of: :team
  belongs_to :company
  belongs_to :creator, class_name: "User", foreign_key: "created_by_id", optional: true

  has_many :point_activity_teams, inverse_of: :team, dependent: :destroy
  has_many :nominations, as: :recipient, dependent: :destroy
  has_many :daily_stats, class_name: "DailyCompanyStat", inverse_of: :team, dependent: :destroy

  DEFAULT_SET = ["Marketing", "Human Resources", "Engineering", "Sales", "IT"]
  validates :company_id, :network, presence: true
  validates :name, presence: true,
                   length: { maximum: 255 },
                   uniqueness: { scope: [:company_id, :deleted_at], case_sensitive: true }

  before_validation :ensure_network
  before_validation :capitalize_first_letter

  delegate :sync_enabled, :sync_teams, to: :company

  def self.default_set
    DEFAULT_SET
  end

  def self.find_from_param(param)
    find_from_recognize_hashid(param) or raise ActiveRecord::RecordNotFound
  end

  def as_json(options={})
    options[:only] ||= [:id, :name]
    options[:methods] ||= [:total_points, :label, :type]
    super(options)
  end

  def log_sync
    Rails.logger.info "Sync'd team: #{self.id}-#{self.name}"
    update_attribute(:synced_at, Time.now)
  end

  def label
    self.name
  end

  def type
    self.class.to_s
  end

  def full_name
    self.label
  end

  def to_param
    self.recognize_hashid
  end

  def recognitions
    @team_recognitions ||= received_recognitions
  end

  def received_recognitions
    Recognition.approved
      .joins(point_activities: :point_activity_teams)
      .where(point_activity_teams: {company_id: self.company_id, team_id: self.id})
      .where(point_activities: {activity_type: 'recognition_recipient'})
      .distinct
  end

  def old_received_recognitions
    member_recognitions.or(team_recognitions)
  end

  def member_recognitions
    member_ids = self.user_teams.map(&:user_id)
    Recognition.approved
      .joins(:recognition_recipients)
      .where(recognition_recipients: {user_id: member_ids, team_id: nil, company_id: nil})
      .distinct
  end

  def team_recognitions
    Recognition.approved
      .joins(:recognition_recipients)
      .where(recognition_recipients: {team_id: self.id, company_id: nil})
      .distinct
  end

  def badges_with_count(opts={})
    set = opts[:restrict_to_interval] ?
      Recognition.restricted_to_interval(self.company.reset_interval).where(id: recognitions.map(&:id)) :
      Recognition.where(id: recognitions.map(&:id))
    set = set.approved

    counts = set.group(:badge_id).count(:badge_id)
    badges = Badge.where(id: counts.keys)
    badge_counts = badges.collect do |badge|
      [badge, counts[badge.id]]
    end
    badge_counts.sort{ |a,b| b[1] <=> a[1] }
  end

  def skills
    # FIXME: stub
    [
      ["Excel", 100],
      ["Powerpoint", 70],
      ["Copywriting", 50],
      ["Speaking", 30],
      ["Email Marketing", 10],
    ].map{|item| Hashie::Mash.new({name: item[0], count: item[1]})}
  end

  def managers
    team_managers.present? ?
      User.where(id: team_managers.pluck(:manager_id)) :
      (company&.company_admins || User.none)
  end

  def add_managers(users)
    users = Array(users)
    users.map do |user|
      team_managers.create(manager: user)
    end
  end

  def remove_managers(users)
    users = Array(users)
    users.map do |user|
      team_managers.where(manager: user).destroy_all.first
    end
  end

  def add_member(user)
    user_teams.create(user: user)
  end

  def remove_member(user)
    users.destroy(user)
  end

  def res_calculator
    @res_calculator ||= ResCalculator.new(self)
  end

  def res_score
    res_calculator.res_score
  end

  def sender_res_score
    res_calculator.sender_res_score
  end

  def can_be_edited?
    # disallow editing if user sync is enabled with sync teams enabled
    !(sync_enabled && sync_teams)
  end

  def avatar_thumb_url
    nil #avatar.thumb.url
  end

  protected
  def ensure_network
    self.network = self.company.domain
  end

  def capitalize_first_letter
    if self.name.present?
      self.name = self.name.strip.tap{ |n| n[0] = n[0].upcase }
    end
  end
end
