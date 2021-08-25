# The primary purpose of this class is to be able to find recognitions
# associated with a team. The definition of associated with a team is
# having been sent or received by a member of that team 
# (at the time the recognition was sent)
class PointActivityTeam < ApplicationRecord
  belongs_to :point_activity
  belongs_to :team

  before_validation { self.company_id = self.team&.company_id }
  validates :company_id, :team_id, :point_activity_id, presence: true
end
