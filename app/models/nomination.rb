# Nominations will only be sent to existing users in the company
# This in contrast to Recognitions which will create and invite users if recipients
# are specified by emails
class Nomination < ApplicationRecord
  include ActionView::Helpers::TextHelper
  include PostConcern
  include IntervalHelper

  belongs_to :recipient, polymorphic: true, optional: true
  belongs_to :recipient_company, class_name: 'Company', optional: true
  belongs_to :campaign, inverse_of: :nominations, optional: true
  has_many :votes, class_name: 'NominationVote', dependent: :destroy do
    def by(user)
      where(nomination_votes: {sender_id: user.id})
    end
  end

  before_validation :set_recipient
  before_validation :set_company

  validates_associated :votes
  validate :check_recipient_or_email
  validate :only_one_recipient
  validate :badge_is_present
  validate :is_awardable?
  validate :recipient_is_not_disabled

  # allow setting multiple recipients to be compatible with recognition form tools
  # validation will catch multiple recipients
  attr_accessor :recipients
  attr_accessor :badge_id # used for error messages for the form


  scope :for_recipient, ->(recipient){ where(recipient_id: recipient.id) }
  scope :for_sender, ->(sender){ joins(:votes).where(nomination_votes: {sender_id: sender.id})}
  scope :for_recipient_company, ->(company){ where(recipient_company_id: company.id) }
  scope :for_company, ->(company_id){ Nomination.joins(:campaign).where(campaigns: { company_id: company_id }) }

  def self.awardable?(recipient, badge)
    globally_awardable?(recipient) && badge_awardable?(recipient, badge)
  end

  def self.globally_awardable?(recipient)
    last_awarded_at = recipient.last_nomination_awarded_at
    interval = recipient.company.nomination_global_award_limit_interval

    if interval.null? || last_awarded_at.nil?
      return true
    else
      return last_awarded_at <= interval.start
    end
  end

  def self.badge_awardable?(recipient, badge)
    last_awarded_badge_at = recipient.company.user_last_awarded_badge_at(recipient, badge)
    interval = badge.nomination_award_limit_interval

    if interval.null? || last_awarded_badge_at.nil?
      return true
    else
      return last_awarded_badge_at <= interval.start
    end
  end

  def self.reason_not_awardable(recipient, badge)
    if !globally_awardable?(recipient)
      award_limit = recipient.company.nomination_global_award_limit_interval
      key = 'reached_global_award_limit'
    elsif !badge_awardable?(recipient, badge)
      award_limit = badge.nomination_award_limit_interval
      key = 'reached_badge_specific_award_limit'
    else
      return nil
    end

    full_key = "activerecord.errors.models.nomination.#{key}"
    reset_interval_noun = ApplicationController.helpers.method(:reset_interval_noun)
    return I18n.t(full_key, interval: reset_interval_noun.call(award_limit).downcase)
  end

  def self.lookup_recipient(recipient, company = nil)
    # TODO: HANDLE_MULTIPLE_NETWORKS
    #             ideally, this is specified by user
    #             However, if we support simple email address, we need to choose
    #             Although, we can draw the line that existing users must be specified via signature
    #             If raw email is sent, then it should be a new user added to the senders network
    #             And we should make switching between networks easier via an account chooser or something
    if recipient.blank?
      return nil
    elsif recipient.match(/\@/)
      return company&.users&.find_by(email: recipient)
    elsif recipient.match(/\:/)
      return Nomination.find_recipient_from_signature(recipient, company)
    elsif recipient.kind_of?(User) || recipient.kind_of?(Team)
      return recipient
    elsif recipient.kind_of?(String)
      nil # invalid email or signature
    else
      raise "Recipient not valid: #{recipient}"
    end
  end

  def award!(awarder)
    if can_award?
      update_columns(is_awarded: true, awarded_at: Time.now, awarded_by_id: awarder.id)
      recipient.update_column(:last_nomination_awarded_at, Time.now)
    else
      raise "Cannot award this recipient because they've already been awarded recently."
    end
  end

  def badge
    campaign && campaign.badge
  end

  def can_award?
    Nomination.awardable?(recipient, badge)
  end

  def self.nominate(sender, params)
    Nominator.nominate(sender, params)
  end

  def toggle_award!(awarder)
    if self.is_awarded?
      self.unaward!
    else
      self.award!(awarder)
    end
  end

  def unaward!

    transaction do
      update_columns(is_awarded: false, awarded_at: nil, awarded_by_id: nil)

      last_awarded_at = Nomination.where(recipient_type: 'User', recipient_id: self.recipient_id, is_awarded: true).maximum(:created_at)
      user = User.find(self.recipient_id)
      user.update_column(:last_nomination_awarded_at, last_awarded_at)

    end

  end

  private

  def badge_is_present
    unless campaign.present? && campaign.badge_id.present?
      errors.add(:badge_id, I18n.t('activerecord.errors.models.nomination.attributes.badge_id.blank'))
    end
  end

  def is_awardable?
    if self.recipient.present? && self.campaign.present?
      unless Nomination.awardable?(self.recipient, self.campaign.badge)
        self.errors.add(:nomination_recipient, Nomination.reason_not_awardable(self.recipient, self.campaign.badge))
      end
    end
  end

  def check_recipient_or_email
    if recipient_id.blank?
      if recipients.blank?
        errors.add(:sender_name, I18n.t('activerecord.errors.models.nomination.recipient_or_email'))
      elsif recipients.count == 1 #multiple recipient are invalid
        if recipients.first =~ Constants::EMAIL_REGEX
          errors.add(:recipient, I18n.t('activerecord.errors.models.nomination.recipient_unknown'))
        else
          errors.add(:recipient, I18n.t('activerecord.errors.models.nomination.recipient_email_invalid'))
        end
      end
    end
  end

  def only_one_recipient
    if recipients && recipients.length > 1
      errors.add(:recipient, I18n.t('activerecord.errors.models.nomination.too_many_recipients'))
    end
  end

  def recipient_is_not_disabled
    if self.recipient.instance_of?(User) && self.recipient.disabled?
      errors.add(:recipient, I18n.t('activerecord.errors.models.nomination.disallow_nominating_disabled_account'))
    end
  end

  def set_company
    self.recipient_company_id = recipient.company_id if self.recipient
  end

  def set_recipient
    unless self.recipients.blank?
      self.recipients.reject!(&:blank?) # housekeeping
      self.recipient = Nomination.lookup_recipient(self.recipients.first, self.campaign&.company) unless self.recipient.kind_of?(User) || self.recipient.kind_of?(Team)
    end
  end

end
