module FbWorkplaceCompanyConcern
  extend ActiveSupport::Concern

  included do
    def self.find_by_fb_workplace_community_id(community_id)
      joins(:settings).where(company_settings: {fb_workplace_community_id: community_id}).first
    end
  end

  def assign_fb_workplace_community_and_token!(community_id, token)
    updates = {}
    updates[:fb_workplace_token] = token.to_s if token.present?
    updates[:fb_workplace_community_id] = community_id if community_id.present?

    # make sure no other companies have this community id
    if CompanySetting.where.not(company_id: self.id, fb_workplace_community_id: community_id).exists?
      settings = CompanySetting.where.not(company_id: self.id).where(fb_workplace_community_id: community_id)
      nil_updates = {}
      nil_updates[:fb_workplace_community_id] = nil if community_id.present?
      nil_updates[:fb_workplace_token] = nil if token.present?
      settings.update_all(nil_updates)
    end

    self.settings.update_columns(updates)

    # FIXME:
    # For some reason isn't allowing us to set the bot settings with web view urls on the first call
    # But we can do it on the 2nd call. ¯\_(ツ)_/¯
    # Regardless, we now need to call #set_bot_settings on every install because of FB's change
    # from single installs to multiple installs. In other words, a customer can install our bot
    # multiple times with different settings (potentially). This also allows them to customize the name and avatar
    # of the bot. 
    self.fb_workplace_client.set_bot_settings(help_only: true)
    self.fb_workplace_client.set_bot_settings(help_only: false)

  end

  def fb_workplace_client
    @fb_workplace_client ||= FbWorkplace::Client.new(self.settings.fb_workplace_token, self.settings.fb_workplace_community_id)
  end

  def fb_workplace_deauthorize!
    self.settings.update_columns(
      fb_workplace_community_id: nil, 
      fb_workplace_token: nil, 
      fb_workplace_post_to_group_id: nil)
    self.users.update_all(fb_workplace_id: nil)
  end

  def fb_workplace_groups(user)
    fb_workplace_client.groups(user.fb_workplace_id)
  rescue RestClient::Unauthorized, RestClient::BadRequest, RestClient::ResourceNotFound => e
    return e
  end

  def can_post_to_fb_workplace?
    settings.fb_workplace_enable_post_to_group? &&
    settings.fb_workplace_community_id.present? &&
    settings.fb_workplace_token.present? &&
    settings.fb_workplace_post_to_group_id.present?
  end

  # NOTE: this used to delegate to the sender user and post to the api from there
  #       But really, for FB Workplace, its a company based integration (token held to the company not user)
  #       as opposed to a user based integration, so flipping this
  #       to delegate to the company and the company client posts
  #       This may no longer be called since we originally went through the company and chose the sender
  #       of the recognition. But that was buggy for anniversary recognitions where the sender was
  #       the system user
  def post_recognition_to_fb_workplace(recognition)
    if self.can_post_to_fb_workplace? && recognition.post_to_fb_workplace?
      self.fb_workplace_client.post_to_group(self.settings.fb_workplace_post_to_group_id, recognition.social_title, recognition.permalink)
    end
  end
end
