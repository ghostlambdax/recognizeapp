# frozen_string_literal: true

# {
#   "draw"=>"1",
#   "columns"=>
#     {"0"=>{"data"=>"created_at", "name"=>"", "searchable"=>"true", "orderable"=>"true", "search"=>{"value"=>"", "regex"=>"false"}},
#      "1"=>{"data"=>"sender", "name"=>"", "searchable"=>"true", "orderable"=>"true", "search"=>{"value"=>"", "regex"=>"false"}},
#      "2"=>{"data"=>"recipients", "name"=>"", "searchable"=>"true", "orderable"=>"true", "search"=>{"value"=>"", "regex"=>"false"}},
#      "3"=>{"data"=>"badge", "name"=>"", "searchable"=>"true", "orderable"=>"true", "search"=>{"value"=>"", "regex"=>"false"}},
#      "4"=>{"data"=>"message", "name"=>"", "searchable"=>"true", "orderable"=>"true", "search"=>{"value"=>"", "regex"=>"false"}},
#      "5"=>{"data"=>"skills", "name"=>"", "searchable"=>"true", "orderable"=>"true", "search"=>{"value"=>"", "regex"=>"false"}}},
#   "order"=>{
#     "0"=>{"column"=>"0", "dir"=>"asc"}},
#   "start"=>"0",
#   "length"=>"10",
#   "search"=>{"value"=>"", "regex"=>"false"}, "_"=>"1427837484094", "network"=>"recognizeapp.com"}
module Report
  class Recognition
    include GlobalID::Identification

    GROUP_DELIMITER = "||"
    ATTR_DELIMITER = ":::"

    attr_reader :company, :from, :to, :opts, :page, :per_page

    def initialize(company, from=50.years.ago, to=Time.current, opts={})
      date_range = DateRange.new(from, to)
      @company = company
      @from = date_range.start_time
      @to = date_range.end_time
      @per_page = opts[:length].to_i
      @opts = opts
      # @page = (opts[:start].to_i / opts[:length].to_i) + 1
    end

    def self.find(serialized_report)
      splits = serialized_report.split(GROUP_DELIMITER)
      report_class = splits[0].split(ATTR_DELIMITER)[1].constantize
      company_id = splits[1].split(ATTR_DELIMITER)[1]
      user_context = splits[2].split(ATTR_DELIMITER)[1]
      from_ = splits[3].split(ATTR_DELIMITER)[1]
      to_ = splits[4].split(ATTR_DELIMITER)[1]
      opts = splits[5].split(ATTR_DELIMITER)[1]
      opts = Rack::Utils.parse_nested_query(opts)

      company = ::Company.find(company_id)
      user = ::User.find(user_context)
      from = ::Time.zone.at(from_.to_i).in_time_zone(user.timezone)
      to = ::Time.zone.at(to_.to_i).in_time_zone(user.timezone)
      full_opts = {user_context: user}.merge(opts).with_indifferent_access

      report_args =
          if report_class == Report::RecognitionsFiltered
            [company, full_opts[:param_scope], from, to, full_opts.except(:param_scope)]
          elsif report_class == Report::RecognitionsByManager
            manager = user
            [manager, from, to, full_opts]
          elsif report_class == Report::Recognition
            [company, from, to, full_opts]
          else
            raise "Unsupported report class!"
          end
      report_class.new(*report_args)
    end

    def id
      opts_as_query_str = if opts.class == Hash
                            opts.except(:user_context).to_query
                          else
                            opts.except(:user_context).to_unsafe_h.to_query
                          end
      groups = [
        ["report_class", self.class.to_s],
        ["Company", company.id],
        ["User", opts[:user_context].id],
        ["from", @from.to_i],
        ["to", @to.to_i],
        ["opts", opts_as_query_str]
      ]
      groups.map { |g| g.join(ATTR_DELIMITER) }.join(GROUP_DELIMITER)
      # "Company::#{company.id}||User::#{opts[:user_context].id}||from::#{@from.to_i}||to::#{@to.to_i}||opts::#{opts_as_query_str}"
    end

    def recognitions
      query
    end

    def recognition_count
      query.size
    end

    def status_filter
      @status_filter ||= opts[:status]&.to_sym
    end

    def total_pending_recognitions
      company.recognitions.pending_approval.size
    end

    protected # these methods are used by child classes

    def recognitions_received_by(user_ids)
      recognition_query_with_flattened_recipients do |query|
        query = yield(query) if block_given?
        query.where(recognition_recipients: { user_id: user_ids })
      end
    end

    def recognitions_sent_by(user_ids)
      recognition_query_with_flattened_recipients do |query|
        query = yield(query) if block_given?
        query.where(recognitions: {sender_id: user_ids})
      end
    end

    # Need to use arel here because of "structural incompatibility" issue - https://stackoverflow.com/q/40742078
    def recognitions_by_different_user_lists(sender_user_ids, receiver_user_ids)
      recognition_query_with_flattened_recipients do |query|
        query = yield(query) if block_given?
        query.where(RecognitionRecipient.arel_table[:user_id].in(receiver_user_ids)
                      .or(::Recognition.arel_table[:sender_id].in(sender_user_ids)))
      end
    end

    private

    # if no status, will only return approved recognitions
    def query
      @query ||= query_by_status
    end

    def query_by_status
      @query_by_status ||= begin
        case opts[:status]&.to_sym
        when :pending_approval
          pending_recognition_query
        when :approved
          # must be approved to have point activities
          approved_recognition_query
        when :denied
          denied_recognition_query
        when nil
          recognition_query_with_flattened_recipients
        else
          raise "Invalid status: #{opts[:status]}"
        end
      end
    end

    def recognition_query
      # company.recognitions
      #   .includes(:badge, :sender, :recognition_tags, :point_activities, recognition_recipients: {user: [:manager, :company]})
      #   .where("recognitions.created_at >= ? AND recognitions.created_at <= ?", from, to)
      RecognitionRecipient
        .joins(:user, recognition: [:badge, :sender])
        .includes(user: [:manager, :teams], recognition: [:badge, :sender, :recognition_tags])
        .where(users: {company_id: company.id})
        .where("recognitions.created_at >= ? AND recognitions.created_at <= ?", from, to)
    end

    # Note: The block yielded in this method allows the result to be filtered before decorating for output
    def recognition_query_with_flattened_recipients
      query = block_given? ? yield(recognition_query) : recognition_query
      vote_map = opts[:include_nomination_votes] ? get_recognition_nomination_vote_map : nil
      RecognitionRecipientDecorator.decorate_collection(query, context: {nomination_vote_map: vote_map})
    end

    def point_activity_query_types
      PointActivity::Type.recognition_recipient
    end

    # its more efficient to query via point activities when trying to get a report with the recipients split out
    def point_activity_query
      set = PointActivity.includes(user: :teams, recognition: [:badge, :sender, :recognition_tags, recognition_recipients: {user: [:manager, :company]}])
        .where(company_id: company.id, activity_type: point_activity_query_types)
        .where("point_activities.created_at >= ? AND point_activities.created_at <= ?", from, to)

      # allow clients to add query conditions before loading
      set = yield(set) if block_given?

      if opts[:include_nomination_votes]
        recognition_nomination_vote_map = get_recognition_nomination_vote_map
      end

      return PointActivityDecorator.decorate_collection(set, context: {nomination_vote_map: recognition_nomination_vote_map})

      # FIXME: This should be moved to a presenter
      # new_set = set.map{ |pa|
      #   pa.recognition.dup_for_reference.tap{ |r|
      #     r.reference_recipient = pa.user
      #     r.reference_activity = pa
      #     r.reference_recipient_teams = pa.user.teams
      #     r.reference_recognition_tags = pa.recognition.recognition_tags
      #     nomination_votes = recognition_nomination_vote_map["#{r.slug}:#{pa.user.id}"] if recognition_nomination_vote_map

      #     if nomination_votes.present?
      #       r.reference_recipient_nominated_badge_ids = nomination_votes.map{|nv| nv.nomination.campaign.badge_id}
      #     end
      # }}
      # return new_set
    end

    def approved_recognition_query
      recognition_query_with_flattened_recipients(&:approved)
      # point_activity_query
    end

    def pending_recognition_query
      recognition_query_with_flattened_recipients(&:pending_approval)
    end

    def denied_recognition_query
      recognition_query_with_flattened_recipients(&:denied)
    end

    # get what nomination badges this person voted for
    def get_recognition_nomination_vote_map
      user = opts[:user_context]
      data = NominationVote.includes(:recognition, nomination: :campaign).joins(:recognition, nomination: :campaign).where(sender_id: user.id).group_by{|nv| "#{nv.recognition.slug}:#{nv.nomination.recipient_id}"} # compound key for quick lookup
      return data
    end
  end
end
