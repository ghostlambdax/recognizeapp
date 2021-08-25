class Campaign < ApplicationRecord
  belongs_to :badge
  belongs_to :company, inverse_of: :campaigns
  has_many :nominations, inverse_of: :campaign, dependent: :destroy

  before_validation :set_interval_from_badge

  validates :badge_id, :start_date, :end_date, :company_id, presence: true
  validates :interval_id, presence: true, if: ->{ badge_id.present? }
  validates :badge_id, uniqueness: {scope: [:start_date, :end_date, :is_archived], case_sensitive: true}

  validate :badge_is_nominatable

  scope :for_company, ->(company){ where(company_id: company.id) }
  scope :for_badge, ->(badge, archived = false) { where(badge: badge, is_archived: archived) }
  scope :for_date, ->(start_date, end_date) { where(start_date: start_date, end_date: end_date) }

  def self.exists_for_badge_and_date?(badge: , start_date: , end_date:)
    for_badge(badge).for_date(start_date, end_date).exists?
  end

  def interval
    Interval.new(interval_id)
  end

  def status_change_valid?
    !self.is_archived || unarchive_toggle_valid?
  end

  private

  def unarchive_toggle_valid?
    search_hash = { badge: self.badge, start_date: self.start_date, end_date: self.end_date }
    is_exists = Campaign.exists_for_badge_and_date?(search_hash)
    self.errors.add(:unarchive, "Active campaign already exists for #{self.badge.short_name} badge") if is_exists
    return !is_exists
  end

  def badge_is_nominatable
    if self.badge && !self.badge.is_nomination?
      errors.add(:badge, I18n.t('activerecord.errors.models.campaign.non_nomination_badge'))
    end
  end

  def set_interval_from_badge
    if self.badge.present? && interval_id.blank?
      self.interval_id = self.badge.sending_interval.to_i
    end
  end
end
