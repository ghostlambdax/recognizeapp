class CompanyAdmin::NominationsController < CompanyAdmin::BaseController
  include ReportsConcern

  layout "company_admin"
  before_action :set_nomination, only: [:award, :votes]

  def index
    is_archived = params[:archive] == "true" ? true : false
    @campaigns = Campaign
                  .includes(:badge, :nominations)
                  .joins(:badge)
                  .for_company(@company)
                  .where(is_archived: is_archived)
                  .where("campaigns.start_date >= ? AND campaigns.end_date <= ?", start_date, end_date)
                  .order("campaigns.interval_id DESC, badges.short_name ASC")

    if params[:badge_id].present?
      @badge = Badge.find(params[:badge_id])
      @campaigns = @campaigns.where(badge_id: params[:badge_id])
    end

  end

  def award
    @nomination.toggle_award!(current_user)
  end

  def votes
    @campaign = @nomination.campaign
    @votes = @nomination.votes
  end

  private

  def set_nomination
    @nomination = Nomination.for_company(@company.id).find(params[:id])
  end

  def get_badge_by_params()
    Badge.cached(params[:badge_id]) if params[:badge_id].present?
  end

end
