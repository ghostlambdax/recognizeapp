class RecognitionTag < ApplicationRecord
  belongs_to :recognition, inverse_of: :recognition_tags
  belongs_to :tag, inverse_of: :recognition_tags

  before_validation :set_tag_name_from_tag, on: :create

  validates :tag_name, presence: true, uniqueness: { scope: :recognition_id, case_sensitive: false }
  validates :recognition, presence: true
  validates :tag, presence: true
  validate :recognition_and_tag_are_of_same_company, on: :create

  private
  def set_tag_name_from_tag
    self.tag_name = tag.name
  end

  def recognition_and_tag_are_of_same_company
    if recognition.authoritative_company.id != tag.company.id
      self.errors.add(:recognition_id, "Recognition and tag must be of the same company")
    end
  end
end
