# frozen_string_literal: true

# NOTE: This class has a nuanced design with respect to recipients and teams
# Case 1: A user is the recipient. That user is a member of a team.
#         This will result in 2 PA records created: a 'recognition_sender' PA and a 'recognition_recipient' PA
#         The 'recognition_sender' PA will have the user_id of the sender and the company_id of the sender. Team id will be nil.
#         The 'recognition_recipient' PA will have the user_id set to that user and the company_id
#         will be set to the company of that user. The team_id will be nil.
#         For each of PA('recognition_sender' and 'recognition_recipient'), we'll loop over the teams
#         of the user record (sender user for 'recognition_sender' & recipient user for 'recognition_recipient')
#         and create a PointActivityTeam for each 'user_team' of that PA.
# Case 2: A team is the recipient.
#         This will similarly result in a single 'recognition_sender' PA. However, it will
#         result in a 'recognition_recipient' for each member of the team.
#         The 'recognition_recipient' PA will have the user_id set to the respective id of
#         each team member. Also, it will have the team_id set to the actually recognized team.
#         That is the nuanced part, because the team_id is NOT set for the 'recognition_sender' PA
#         as it was sent by a user not a team.
#
#         So, when the team_id is set, that tells us it was actually a Team that was recognized but the
#         team member (user) is given their own PA record. This is different than the company_id which is
#         always there and based on the PA's user's company.
#
#         So, to summarize, the user_id and company_id will always be set on a PA. But the team_id
#         will only be set when the PA is of type 'recognition_recipient' and the recognition had a recipient
#         of the proper Team.
#
#         NOTE: There is an edge case here if you were to recognize a team and an individual who is part of that
#               team separately. In this case, the user gets double points (and double PA's). They'll have a
#               'recognition_recipient' PA for them individually and one where the team_id is set.
class PointActivity < ApplicationRecord
  ALLOWED_TYPES = [
    "recognition_recipient",
    "recognition_sender",
    "recognition_approval_giver",
    "recognition_approval_receiver",
    "redemption",
    "redemption_denial",
    "completed_task",
    "point_expiration",
  ]

  belongs_to :user
  belongs_to :recognition, optional: true
  belongs_to :company

  has_many :point_activity_teams, inverse_of: :point_activity, dependent: :destroy

  before_validation :set_company

  validates :amount, :activity_type, :company_id, :network, :user_id, presence: true
  validates :is_redeemable, :inclusion => {:in => [true, false]}
  validates :activity_object_type, :activity_object_id, presence: true
  validates :activity_type, inclusion: {in: ALLOWED_TYPES}

  after_commit :snapshot_user_teams, on: :create

  scope :redeemable, ->{ where(is_redeemable: true)}
  scope :earned_points_only, ->{ where.not(activity_type: ['redemption', 'redemption_denial', 'point_expiration']) }
  scope :redemptions, ->{ where(activity_type: ['redemption', 'redemption_denial'])}
  scope :completed_tasks, -> { where(activity_type: 'completed_task') }

  def self.for_activity(obj, user)
    where(user_id: user.id).
    where(activity_object_type: obj.class.to_s, activity_object_id: obj.id)

  end

  def self.types
    ALLOWED_TYPES
  end

  def self.reportable_types
    # stub if we want to restrict the activity types
    # that we provide reporting on, for now, show all
    self.types - ["point_expiration"]
  end

  def activity_object=(object)
    self.activity_object_type = object.class.to_s
    self.activity_object_id = object.id
  end

  private
  def set_company
    self.company_id = user.company_id
    self.network = user.network
  end

  def snapshot_user_teams
    # transaction for faster inserts if many teams
    ActiveRecord::Base.transaction do
      user.user_teams.each do |user_team|
        # If the point activity is from a team recognition
        # only create PointActivityTeams for that team
        # This addresses case where you recognize TeamA
        # but the members of TeamA are also on other teams
        # But those other teams aren't relevant here.
        # Without this, if you recognize TeamA, and member of TeamA
        # is also member of TeamB, this recognition will show up
        # on TeamB's stream.
        next if self.team_id.present? && user_team.team_id != self.team_id

        # FIXME:
        #   - This is still problematic though because
        #     we will still have redundant PointActivityTeam
        #     records. For instance, if two recognition recipients are both
        #     on the same team, we need to be careful on how we query this
        #     table. For instance, for point calculations. If we join
        #     PointActivity.joins(:point_activity_teams), it will result in multiple
        #     records per single point activity and therefore you can't do aggregate
        #     sum calculations on them. I believe this is why in Report::Team#calculate_team_points
        #     there is .to_a.sum(&:amount) [Ruby sum] rather than just .sum(:amount) [ActiveRecord sum]
        #
        PointActivityTeam.create!(
          point_activity_id: self.id,
          team_id: user_team.team_id,
          company_id: self.company_id,
          recognition_id: self.recognition_id
        )
      end
    end
  rescue StandardError => e
    Rails.logger.debug "Caught exception snapshotting user teams"
    Rails.logger.debug e.to_s
    Rails.logger.debug self.attributes.inspect
    ExceptionNotifier.notify_exception(e, data: self.attributes)
  end

  class Type
    def self.recognition_recipient
      "recognition_recipient"
    end

    def self.recognition_sender
      'recognition_sender'
    end
  end
end
