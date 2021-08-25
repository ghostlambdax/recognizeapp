class JobStatus < ApplicationRecord
  belongs_to :company
  belongs_to :initiator, foreign_key: :initiator_id, class_name: "User"

  validates :name, presence: true
  validates :company_id, presence: true

  def record(initiator: nil)
    self.initiator_id = initiator.id if initiator.present?
    self.started_at = Time.now
    save!
    
    yield(self)

    self.stopped_at = Time.now
    save!
  end
end
