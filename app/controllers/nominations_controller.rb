class NominationsController < ApplicationController
  include GonHelper

  before_action :set_gon_team_counts, only: [:new, :new_chromeless]

  filter_access_to :all, attribute_check: true, load_method: :current_user

  def index
    @nominations = Nomination
      .joins(:votes, campaign: :badge)
      .for_sender(current_user)
      .order("nomination_votes.created_at desc")

    @nomination = @nominations.first

  end

  def new
    @nomination_vote = NominationVote.new
  end

  def create
    @nomination_vote = Nomination.nominate(current_user, nomination_params.merge({company: @company}))
    respond_with @nomination_vote, flash: {notice: t("nominations.has_been_sent")}, location: nominations_path
  end

  def new_chromeless
    @nomination_vote = NominationVote.new
    @pageName = "nomination"
    @jsClass = "Nomination"
    @user_team_map = current_user.company.user_team_map

    #@recipient = recipient_from_params

    render action: "new", layout: "application_chromeless"
  end

  private
  def nomination_params
    params.require(:nomination_vote).permit(:message, :is_quick_nomination, :request_form_id, :recognition_slug, nomination: [:badge_id], recipients: [])
  end

end
