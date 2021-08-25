class NominationVote < ApplicationRecord
  include ActionView::Helpers::TextHelper
  include IntervalHelper

  enable_duplicate_request_preventer

  attr_accessor :recognition_slug

  belongs_to :nomination, counter_cache: :votes_count, validate: true
  belongs_to :sender, class_name: 'User'
  belongs_to :sender_company, class_name: 'Company'
  belongs_to :recognition, optional: true

  before_validation :convert_recognition_slug
  before_validation :set_sender_company

  validates :sender_id, :nomination, presence: true
  validates :sender_company_id, presence: true, if: ->{ sender_id.present? }
  validate :is_within_sending_limits, on: :create
  validate :message_is_required, unless: :is_quick_nomination?
  validate :nomination_is_awardable, on: :create
  validate :self_nomination_is_valid
  validate :sender_has_permission_to_send_badge, on: :create

  scope :sent_by, ->(sender) { where(sender_id: sender.id) }
  def self.for_company(company)
    where(sender_company_id: company.id)
  end

  def badge
    self.nomination.campaign.try(:badge)
  end

  private
  def set_sender_company
    self.sender_company_id = self.sender.company_id if self.sender
  end

  def is_within_sending_limits
    if badge.present? && badge.sending_frequency.present? && badge.sending_frequency.to_i > 0
      is_within_badge_sending_limits
    elsif sender && sender.company.recognition_limit_frequency.present? && sender.company.recognition_limit_frequency.to_i > 0
      is_within_company_sending_limits
    end
  end

  def is_within_badge_sending_limits
    start_time = badge.sending_interval.start
    interval_sent_nominations = sender.sent_nomination_votes.joins(nomination: :campaign).where("nomination_votes.created_at >= ? AND campaigns.badge_id = ?", start_time, badge.id)
    if interval_sent_nominations.size >= badge.sending_frequency
      err =  I18n.t('activerecord.errors.models.recognition.is_within_badge_sending_limits',
                        frequency: pluralize(badge.sending_frequency, 'time', 'times'),
                        interval: reset_interval_noun(badge.sending_interval))
      self.errors.add(:base, err) unless self.errors[:base].include?(err)
    end
  end

  def is_within_company_sending_limits
    start_time = sender.company.recognition_limit_interval.start
    interval_sent_nominations = sender.sent_nomination_votes.joins(:nomination).where("nomination_votes.created_at >= ?", start_time)
    sender_company_recognition_limit_frequency = sender.company.recognition_limit_frequency
    if interval_sent_nominations.size >= sender_company_recognition_limit_frequency
      err = I18n.t('activerecord.errors.models.recognition.is_within_company_sending_limits',
                   frequency: I18n.t('dict.frequency.badges', count: sender_company_recognition_limit_frequency),
                   interval: reset_interval_noun(sender.company.recognition_limit_interval))
      self.errors.add(:base,err) unless self.errors[:base].include?(err)
    end
  end

  def message_is_required
    if sender && sender.company.nomination_message_is_required? && message.blank?
      self.errors.add(:message, I18n.t('activerecord.errors.messages.blank'))
    end
  end

  def nomination_is_awardable
    if nomination.recipient.present? && nomination.badge.present?
      unless Nomination.awardable?(nomination.recipient, nomination.badge)
        self.errors.add(:nomination_recipient, Nomination.reason_not_awardable(nomination.recipient, nomination.badge))
      end
    end
  end

  def self_nomination_is_valid
    return unless nomination.recipient.present? && nomination.badge.present? && self.sender.present?
    return unless nomination.recipient == self.sender

    # if we get here, we're a self nomination
    unless nomination.badge.allow_self_nomination
      self.errors.add(:nomination_recipient, I18n.t('activerecord.errors.models.nomination.self_nomination_not_allowed'))
    end
  end

  def sender_has_permission_to_send_badge
    if self.badge.present? &&
        self.badge.roles_with_permission(:send).present? &&
        !self.sender.sendable_badges.include?(self.badge)
      errors.add(:base, I18n.t("activerecord.errors.models.recognition.sender_doesnt_have_permission_to_send_badge"))
    end
  end

  # Allow passing recognition slug
  # So, need to set recognition id if slug is passed
  def convert_recognition_slug
    if self.recognition_slug.present?
      self.recognition_id = Recognition.find(self.recognition_slug).id
    end
  end
end
