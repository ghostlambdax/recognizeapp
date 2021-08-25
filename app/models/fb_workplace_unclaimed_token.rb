class FbWorkplaceUnclaimedToken < ApplicationRecord
  validates :community_id, :token, presence: true
  validates :community_id, uniqueness: { case_sensitive: true }

  def fb_workplace_client
    FbWorkplace::Client.new(self.token, self.community_id)
  end
end
