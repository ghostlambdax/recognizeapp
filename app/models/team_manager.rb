class TeamManager < ApplicationRecord
  belongs_to :team, inverse_of: :team_managers
  belongs_to :manager, class_name: "User"

  validates :team, :manager_id, presence: true
  validate :manager_is_in_company
  validates :manager_id, uniqueness: {scope: :team_id, case_sensitive: true, message: I18n.t("activerecord.errors.models.team_manager.already_manager")}

  private
  def manager_is_in_company
    unless manager.company_id == team.company_id
      errors.add(:manager_id, I18n.t("activerecord.errors.models.team_manager.must_be_in_company"))
    end
  end
end
