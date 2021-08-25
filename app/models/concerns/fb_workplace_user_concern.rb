module FbWorkplaceUserConcern
  extend ActiveSupport::Concern

  included do    
  end

  module ClassMethods
    # FIXME: Once we implement Workplace sync,
    #        make this respect sync settings
    def sync_fb_workplace_data(user_id)
      # This has a sister method in 
      # lib/fb_workplace/webhook.rb#init_recognize_user
      u = User.find(user_id)
      client = u.company.fb_workplace_client

      return unless u.fb_workplace_id.present?
      return unless client.connected?
      
      fb_user = client.user(u.fb_workplace_id)
      if fb_user.present? && fb_user.email.present?
        u.update_columns(
          email: fb_user.email,
          first_name: fb_user.first_name,
          last_name: fb_user.last_name,
          job_title: fb_user.title
        )
      else
        Rails.logger.info "There was a problem properly trying to sync workplace user"
        Rails.logger.info "#{u.fb_workplace_id} => #{fb_user.inspect}"
      end
    end
  end

  def fb_workplace_client
    @fb_workplace_client ||= FbWorkplace::Client.new(self.fb_workplace_token, self.company.settings.fb_workplace_community_id)    
  end

  def fb_workplace_member
    @fb_workplace_member ||= begin
      self.company.fb_workplace_client.member(self.email, group_id: self.company.settings.fb_workplace_post_to_group_id) rescue nil
    end
  end

  def fb_workplace_token
    self.company.settings.fb_workplace_token rescue nil
  end

  # NOTE: this used to directly call the api
  #       But really, for FB Workplace, its a company based integration (token held to the company not user)
  #       as opposed to a user based integration, so flipping this
  #       to delegate to the company and the company client posts
  #       This may no longer be called since we originally went through the company and chose the sender
  #       of the recognition. But that was buggy for anniversary recognitions where the sender was
  #       the system user
  def post_recognition_to_fb_workplace(recognition)
    self.company.post_recognition_to_fb_workplace(recognition)
  end

  def can_post_to_fb_workplace?
    self.company.can_post_to_fb_workplace?
  end

end