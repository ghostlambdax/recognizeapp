class UserRole < ApplicationRecord
  belongs_to :user

  validates :company_id, presence: true

  before_validation :set_company
  def role
    Role.find(role_id)
  end

  private
  def set_company
    self.company_id = self.user.company_id
  end
end
