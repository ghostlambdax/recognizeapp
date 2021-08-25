class UserTeam < ApplicationRecord

  acts_as_paranoid

  belongs_to :user
  belongs_to :team

  validates_uniqueness_of :user_id, { scope: [:team_id, :deleted_at], case_sensitive: true }
  validate :user_and_team_are_in_same_company, on: [:create, :update]

  private
  def user_and_team_are_in_same_company
    if user.present? && team.present? && user.company_id != team.company_id
      self.errors.add(:user_id, "User and team must be in the same company")
    end
  end
end
