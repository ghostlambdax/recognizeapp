class RecognitionApproval < ApplicationRecord

  acts_as_paranoid  

  belongs_to :giver, :class_name => "User", counter_cache: :given_recognition_approvals_count
  belongs_to :recognition, counter_cache: :approvals_count

  before_validation { self.company_id = self.giver&.company_id }

  validates :company_id, :giver_id, :recognition_id, presence: true
  validate :disallow_from_recognition_sender_or_receiver, :disallow_multiple_on_same_recognition

  protected
  # def disallow_from_users_in_different_company
  #   unless [recognition.sender_company_id, recognition.recipient_company_id].include?(giver.company_id)
  #     errors.add(:base, "You may not plus one a recognition from a different company")
  #   end
  # end
  
  def disallow_from_recognition_sender_or_receiver
    if recognition.participants.include?(giver)
      errors.add(:base, "You may not like a recognition that you have sent or received")
    end
  end
  
  def disallow_multiple_on_same_recognition
    if self.class.where(giver_id: giver_id, recognition_id: recognition_id).limit(1).present?
      errors.add(:base, "You may not like a recognition more than once")
    end
  end
end
