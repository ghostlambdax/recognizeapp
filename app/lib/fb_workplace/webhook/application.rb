class FbWorkplace::Webhook::Application < FbWorkplace::Webhook::Base
  class WorkplaceUninstall < FbWorkplace::Webhook::Change
    def call
      FbWorkplace::Logger.log "received request to deauth #{self.data}"
      company = Company.joins(:settings).where(company_settings: {fb_workplace_community_id: community_id}).first
      company.fb_workplace_deauthorize! if company
      FbWorkplaceUnclaimedToken.where(community_id: community_id).destroy_all

      FbWorkplace::Logger.log "deauthorized:  #{company.try(:domain) || community_id}"
    end
    
    def acceptable?
      unless CompanySetting.find_by(fb_workplace_community_id: community_id).present? || FbWorkplaceUnclaimedToken.where(community_id: community_id).present?
        FbWorkplace::Logger.log("No company found for community id #{community_id}")
        return false
      end
      
      return true
    end
  end
end