class RecognitionRecipient < ApplicationRecord
  acts_as_paranoid
  serialize :metadata

  belongs_to :recognition, inverse_of: :recognition_recipients
  belongs_to :user, counter_cache: :received_recognitions_count

  # it would be nice to have this validation on all the time , but can't due to save order when 
  # saving a recognition that is sent to a new user.  This model gets saved before the user model 
  # gets saved so in that case we don't have recipient company id and network
  validates :recipient_company_id, :sender_company_id, :recipient_network, presence: true, if: -> { user.persisted? }

  before_validation :set_company
  # before_create :snapshot_team_member_ids

  scope :of_approved_recognitions, -> { joins(:recognition).where("recognitions.status_id = ?", Recognition.status_id_by_name(:approved)) }
  scope :pending_approval, -> { joins(:recognition).where("recognitions.status_id = ?", Recognition.status_id_by_name(:pending_approval)) }
  scope :denied, -> { joins(:recognition).where("recognitions.status_id = ?", Recognition.status_id_by_name(:denied)) }

  # just an alias
  def self.approved
    of_approved_recognitions
  end

  def user
    ::User.unscoped { super }
  end

  private

  def set_company
    self.recipient_company_id = user.company_id
    self.recipient_network = user.network
    self.sender_company_id = recognition.try(:sender_company_id) || recognition.try(:sender).try(:company_id)
  end

end
