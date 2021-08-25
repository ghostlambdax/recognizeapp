class CompanyAdmin::CampaignsController < CompanyAdmin::BaseController
  layout "company_admin"
  before_action :set_campaign

  def show
    @nominations = @campaign.nominations.joins(votes: :sender).includes(votes: :sender).sort_by{|n| [-1*n.votes_count, n.recipient.label]}
  end

  def archive
    @campaign.toggle!(:is_archived) if @campaign.status_change_valid?
  end

  private

  def set_campaign
    @campaign = @company.campaigns.find(params[:id])
  end
end
