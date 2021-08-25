class Authentication < ApplicationRecord
  belongs_to :user, inverse_of: :authentications
  validates :uid, :provider, :presence => true
  validates :uid, uniqueness: {scope: [:user_id, :provider], case_sensitive: false}

  serialize :credentials
  serialize :extra, JSON
  after_create :update_yammer_id

  def oauth_scopes
    extra["params"]["scope"] rescue nil
  end

  protected
  def google?
    provider.to_sym == :google_oauth2
  end

  def yammer?
    provider.to_sym == :yammer
  end

  def microsoft_graph?
    provider.to_sym == :microsoft_graph
  end

  def update_yammer_id
    if self.provider == "yammer"
      self.user.update_attribute(:yammer_id, self.uid)
    end
  end
end
