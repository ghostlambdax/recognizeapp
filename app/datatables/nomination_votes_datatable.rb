# frozen_string_literal: true

class NominationVotesDatatable < Litatable
  COLUMN_SPEC = [
    {attribute: :date, orderable: true, sort_column: "nomination_votes.created_at"},
    {attribute: :campaign_period, orderable: false},
    {attribute: :badge, orderable: true, sort_column: "badges.short_name"},
    {attribute: :nominee_employee_id, orderable: false, colvis: :hide, title: "Nominee Employee Id"},
    {attribute: :nominee_first_name, orderable: false, colvis: :hide, title: "Nominee First Name"},
    {attribute: :nominee_last_name, orderable: false, colvis: :hide, title: "Nominee Last Name"},
    {attribute: :nominee_email, orderable: false, colvis: :hide, title: "Nominee Email"},
    {attribute: :nominee_full_name, orderable: false, title: "Nominee Full Name"},
    {attribute: :nominator_employee_id, orderable: false, colvis: :hide, title: "Nominator Employee Id"},
    {attribute: :nominator_first_name, orderable: false, colvis: :hide, title: "Nominator First Name"},
    {attribute: :nominator_last_name, orderable: false, colvis: :hide, title: "Nominator Last Name"},
    {attribute: :nominator_email, orderable: false, colvis: :hide, title: "Nominator Email"},
    {attribute: :nominator_full_name, orderable: false, title: "Nominator Full Name"},
    {attribute: :message, orderable: false},
    {attribute: :awarded, orderable: false},
    {attribute: :archived, orderable: false}
  ].freeze

  def serializer
    NominationVotesSerializer
  end

  def namespace
    'nomination_votes'
  end

  private

  def all_records
    votes = NominationVote
      .joins(:sender, nomination: [campaign: :badge])
      .includes(:sender, nomination: [campaign: :badge])
      .where(nomination_votes: {sender_company_id: company.id})

    votes = votes.order(sort_columns_and_directions.to_s) if params[:order].present?
    votes
  end

  def columns_to_search_in
    badge_columns = %w[short_name].map { |attr| "badges.#{attr}" }
    nomination_vote_columns = %w[message].map { |attr| "nomination_votes.#{attr}" }
    nominator_columns = %w[first_name last_name email display_name employee_id].map { |attr| "users.#{attr}" }
    badge_columns + nomination_vote_columns + nominator_columns
  end

  def filtered_records
    votes = all_records_filtered_by_date_range(table: :nomination_votes)

    search_term = params.dig(:search, :value)
    if search_term.present?
      votes = if search_term.match(/not.awarded/i)
        search_term.gsub!(/not.awarded/i, '')
        votes.where(nominations: {is_awarded: false})
      elsif search_term.match(/not.archived/)
        search_term.gsub!(/not.archived/i, '')
        votes.where(campaigns: {is_archived: false})
      elsif search_term.match(/awarded/i)
        search_term.gsub!(/awarded/, '')
        votes.where(nominations: {is_awarded: true})
      elsif search_term.match(/archived/i)
        search_term.gsub!(/archived/, '')
        votes.where(campaigns: {is_archived: true})
      else
        votes
      end
    end
    # The `search_term` could have beeen present earlier but could be blank by now due to `gsub!` above.
    votes = filtered_set(votes, search_term, columns_to_search_in) if search_term.present?
    votes.paginate(page: page, per_page: per_page)
  end

  class NominationVotesSerializer < BaseDatatableSerializer
    attributes :id, :date, :timestamp, :badge, :campaign_period, :message, :awarded, :archived,
               :nominee_employee_id, :nominee_first_name, :nominee_last_name, :nominee_email, :nominee_full_name,
               :nominator_employee_id, :nominator_first_name, :nominator_last_name, :nominator_email, :nominator_full_name

    delegate :employee_id, :first_name, :last_name, :email, :full_name, to: :nominee, prefix: true
    delegate :employee_id, :first_name, :last_name, :email, :full_name, to: :nominator, prefix: true

    def timestamp
      vote.created_at.to_f.to_s
    end

    def awarded
      vote.nomination.is_awarded? ? "yes" : "no"
    end

    def archived
      campaign.is_archived? ? "yes" : "no"
    end

    def badge
      campaign.badge.short_name
    end

    def campaign
      vote.nomination.campaign
    end

    def campaign_period
      reset_interval_label_with_time(campaign.interval, campaign.start_date)
    end

    def date
      l(vote.created_at, format: :friendly_with_time)
    end

    def current_user
      context.current_user
    end

    def DT_RowId
      "nomination_vote_row_#{vote.id}"
    end

    def vote
      @object
    end

    def nominator
      vote.sender
    end

    def nominee
      recipient = vote.nomination.recipient
      nominee_is_a_team? ? TeamNominee.new(recipient) : recipient
    end

    def nominee_is_a_team?
      vote.nomination.recipient.is_a? Team
    end

    class TeamNominee
      attr_reader :team
      delegate :full_name, to: :team

      def initialize(team)
        @team = team
      end

      %i[employee_id first_name last_name email].each do |dynamic_method|
        define_method(dynamic_method.to_s) { nil }
      end
    end
  end
end
