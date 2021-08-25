class Report::Company
  include Report::CacheManager::Company

  attr_reader :company, :from, :to, :opts, :user_status_scope

  def initialize(company, from=50.years.ago, to=Time.current, opts={})
    @company = company
    @from = from
    @to = to
    @opts = opts
    @user_status_scope = opts[:user_status_scope] || :active
  end

  def users
    company.users.send(user_status_scope)
  end

  def get_team_user_ids(team_id)
    UserTeam.where(team_id: team_id).pluck(:user_id)
  end

  def get_company_role_user_ids(company_role_id)
    UserCompanyRole.where(company_role_id: company_role_id).pluck(:user_id)
  end

  def users_in_search_scope(scope_opts = {})
    # hack for now to avoid n+1 on user query
    team_id = scope_opts[:team_id]
    users.where(team_id.present? ? {id: get_team_user_ids(team_id)} : 'true')
  end

  def interval
    opts[:interval]
  end

  def inactive?
    received_recognitions.size == 0 && sent_recognitions.size == 0
  end

  # Benchmark 5/1/2014 - metro - 27s
  def leaders
    @leaders ||= get_leaders#Rails.cache.fetch(ckm_lookup_key(:leaders)){ get_leaders }
  end

  def sent_recognitions
    @recognitions ||= company.sent_recognitions.approved.where("recognitions.created_at >= ? AND recognitions.created_at <= ?", from, to)
  end
  
  def received_recognitions
    @received_recognitions ||= company.received_recognitions.approved.where("recognitions.created_at >= ? AND recognitions.created_at <= ?", from, to)
  end

  def recognition_recipients
    @recognition_recipients ||= company.recognition_recipients.of_approved_recognitions.joins(:recognition).where("recognitions.created_at >= ? AND recognitions.created_at <= ?", from, to)
  end

  def unique_recipient_count
    (recognition_recipients.pluck('recognition_recipients.user_id').uniq & users.map(&:id)).size
  end

  def unique_sender_count
    sent_recognitions.distinct('recognitions.sender_id').pluck('recognitions.sender_id').uniq.size
  end

  def max_recognition_recipient_id
    RecognitionRecipient.includes(:recognition).joins(:recognition)
    .of_approved_recognitions
    .where(recipient_company_id: company.id)
    .where("recognitions.created_at >= ? AND recognitions.created_at <= ?", from, to)
    .maximum(:id)
  end

  # using badge query instead of company.sent_recognitions association query - which is done in sent_recognitions() above
  #   this is in order to map anniversary recognitions under relevant recipient companies
  #   instead of mapping it all under system company
  #
  # Note: this method is used for daily emails only (as of 14/11/2020)
  #
  def top_recognitions
    Recognition
      .for_company(company) # badge query
      .where(created_at: from..to)
      .reorder([approvals_count: :desc, updated_at: :desc, id: :desc]) # :updated_at & :id are default sort atts
  end

  def top_public_recognitions
    top_recognitions.not_private
  end

  def leaderboard_relative_to(user, attr, limit)
    set = user_leaderboard(attr).values
    i = set.index{|u| u[:id] == user.id}

    return leaderboard(set, i, limit)
  end

  def team_leaderboard(attr)
    set = company.teams.map{|t| Report::Team.new(t, from, to, opts)}
    return sort_teams_by(set, attr)
  end

  def user_leaderboard(attr)
    sort_leaders_by(attr)
  end

  def first_place_leaders(attr)
    leaders = user_leaderboard(attr)
    leaders.select{|id, leader| leader[:rank] == 1}
  end

  def first_place_teams(attr)
    teams = team_leaderboard(attr)
    teams.select{|team| team.rank == 1}
  end
    
  def top_badges(opts={})
    limit = opts[:limit] || 100000000
    set = received_recognitions.group_by(&:badge_id)
    counts = set.inject({}){|hash, (badge_id, recognitions)| hash[badge_id] = recognitions.size; hash}
    sorted_counts = counts.sort{|a,b| b[1] <=> a[1]}
    badge_counts = sorted_counts[0..limit].inject({}){ |hash, (badge_id, count)| hash[badge_id] = {badge: Badge.cached(badge_id), count: count};hash}
    return badge_counts
  end

  def attribute_value_filter
    @attribute_value_filter ||= AttributeValueFilter.new(@opts[:attribute_filter_key], @opts[:attribute_filter_value])
  end

  private

  def sort_leaders_by(attr)
    sorted_leaders = leaders.values.sort_by{|user| user[attr]}.reverse
    rank = 0
    sorted_leaders.each_with_index do |leader, index|
      leader[:behind_user] = sorted_leaders[index-1][:id] if index > 0
      leader[:in_front_of_user] = sorted_leaders[index+1][:id] if sorted_leaders.length > index + 1
      rank = (index > 0 && leader[attr] == sorted_leaders[index-1][attr]) ? rank : rank + 1
      leader[:rank] = rank
    end

    sorted_leaders.inject({}) {|hash, leader| hash[leader[:id]] = leader;hash}
  end  

  def sort_teams_by(set, attr)
    sorted_teams = set.sort_by(&attr).reverse    
    rank = 0
    sorted_teams.each_with_index do |team, index|
      rank = (index > 0 && team.send(attr) == sorted_teams[index-1].send(attr)) ? rank : rank + 1      
      team.rank = rank
    end
  end

  def leaderboard(set, index, count)
    case
    when index < (count/2) # Towards the beginnning
      leaderboard = set[0..(count-1)]

    when index > set.length-(count/2) # Towards the end
      leaderboard = set[set.length-count..set.length]  

    else # somewhere in the middle
      leaderboard = set[index-(count/2)..index+(count/2)]
    end

    return leaderboard    
  end

  def get_leaders
    # user_set = opts[:team_id].present? ? Team.find(opts[:team_id]).users : company.users
    if opts[:points_only]
      # this is fastest, as long as we only need points
      get_leaders_by_points_query
    elsif opts[:received_recognitions_only]
      get_leaders_by_recognitions_query(:received_recognition)
    elsif opts[:sent_recognitions_only]
      get_leaders_by_recognitions_query(:sent_recognition)
    elsif opts[:received_points_only]
      get_leaders_by_received_points_query
    else
      # for backwards compatibility
      get_leaders_by_report
    end

  end

  def get_leaders_by_points_query
    query_set = PointActivity
      .earned_points_only
      .joins(:user)
      .where("point_activities.company_id = ?", company.id)
      .where("users.company_id = ?", company.id)
      .where("point_activities.created_at >= ? AND point_activities.created_at <= ? ", from, to)
      .where(opts[:badge_id] ? {point_activities: {badge_id: opts[:badge_id]}}  : 'true')
      .where(opts[:team_id] ? {point_activities: {user_id: get_team_user_ids(opts[:team_id])}}  : 'true')
      .where(opts[:company_role_id] ? {point_activities: {user_id: get_company_role_user_ids(opts[:company_role_id])}}  : 'true')
      .select("point_activities.user_id, SUM(point_activities.amount) as points")
      .group("point_activities.user_id")
      .order("points desc")

    filtered_set = attribute_value_filter.valid? ?
               query_set.having(get_attribute_filter_query("points")) :
               query_set

    user_map = users_in_search_scope(team_id: opts[:team_id]).inject({}){|hash, user| hash[user.id] = user;hash}

    result = filtered_set.inject({}){|hash, totals|
      user = user_map[totals.user_id]
      if user.present? # protect in case there are point activities for deleted users, shouldn't happen, but it might...
        hash[totals.user_id] = UserReportDecorator.new(user, totals)
      end
      hash
    }

    # Back fill users who weren't in the query set, and set their respective points to 0,
    # only if the search should show records with 0 value.
    # For example: if a filter `gt 3` exists, and a user is filtered out by this condition, don't fill the user back in
    # with points equal to 0.
    query_set_user_ids = query_set.map{ |r| r.user_id }
    user_map.reject{ |id, user| query_set_user_ids.include?(id) }.each do |id, user|
      result[id] ||= UserReportDecorator.new(user, Hashie::Mash.new(points: 0))
    end

    return result
  end

  def get_leaders_by_received_points_query
    set = PointActivity
    .where(company_id: company.id)
    .where("point_activities.created_at >= ? AND point_activities.created_at <= ? ", from, to)
    .where("point_activities.activity_type = ? OR point_activities.activity_type = ?", "recognition_recipient", "recognition_approval_receiver")
    .where(opts[:badge_id] ? {point_activities: {badge_id: opts[:badge_id]}}  : 'true')
    .where(opts[:team_id] ? {point_activities: {user_id: get_team_user_ids(opts[:team_id])}}  : 'true')
    .where(opts[:company_role_id] ? {point_activities: {user_id: get_company_role_user_ids(opts[:company_role_id])}}  : 'true')
    .select("point_activities.user_id, SUM(point_activities.amount) as points")
    .group("point_activities.user_id")
    .order("points desc")

    user_map = users_in_search_scope(team_id: opts[:team_id]).inject({}){|hash, user| hash[user.id] = user;hash}

    result = set.inject({}){|hash, totals| 
      user = user_map[totals.user_id]
      if user.present? # protect in case there are point activities for deleted users, shouldn't happen, but it might...
        hash[totals.user_id] = UserReportDecorator.new(user, totals)
      end
      hash
    }

    # back fill users who have 0 points
    user_map.each do |id, user|
      if user.present? # protect in case there are point activities for deleted users, shouldn't happen, but it might...
        result[id] ||= UserReportDecorator.new(user, Hashie::Mash.new(points: 0))
      end
    end

    return result
  end

  def get_leaders_by_recognitions_query(recognition_type)
    point_activity_type = recognition_type == :sent_recognition ? :recognition_sender : :recognition_recipient
    query_set = PointActivity
      .joins(:user)
      .where("point_activities.activity_type = ?", PointActivity::Type.send(point_activity_type))
      .where("point_activities.company_id = ?", company.id)
      .where("users.company_id = ?", company.id)
      .where("point_activities.created_at >= ? AND point_activities.created_at <= ? ", from, to)
      .where(opts[:badge_id] ? {point_activities: {badge_id: opts[:badge_id]}}  : 'true')
      .where(opts[:team_id] ? {point_activities: {user_id:  get_team_user_ids(opts[:team_id])}}  : 'true')
      .where(opts[:company_role_id] ? {point_activities: {user_id:  get_company_role_user_ids(opts[:company_role_id])}}  : 'true')
      .select("point_activities.user_id, COUNT(recognition_id) as #{recognition_type}_count")
      .group("point_activities.user_id")
      .order("#{recognition_type}_count desc")


    filtered_set =  attribute_value_filter.valid? ?
               query_set.having(get_attribute_filter_query("#{recognition_type}_count")) :
               query_set

    user_map = users_in_search_scope(team_id: opts[:team_id]).inject({}){|hash, user| hash[user.id] = user;hash}

    result = filtered_set.inject({}){|hash, totals|
      user = user_map[totals.user_id]
      if user.present? # protect in case there are point activities for deleted users, shouldn't happen, but it might...
        hash[totals.user_id] = UserReportDecorator.new(user, totals)
      end
      hash
    }

    # Back fill users who weren't in the query set, and set their respective recognition_type count to 0,
    # only if the search should show records with 0 value.
    # For example: if a filter `gt 3` exists, and a user is filtered out by this condition, don't fill the user back in
    # with recognition_type count equal to 0.
    query_set_user_ids = query_set.map{ |r| r.user_id }
    user_map.reject{ |id, user| query_set_user_ids.include?(id) }.each do |id, user|
      result[id] ||= UserReportDecorator.new(user, Hashie::Mash.new("#{recognition_type}_count": 0))
    end
    
    return result
  end  

  def get_leaders_by_report
    if opts[:team_id].present?
      set = company.teams.find(opts[:team_id]).users.send(user_status_scope)
    else
      set = company.users.send(user_status_scope)
    end

    set.inject({}) do |hash, user|

      user_report = Report::User.new(user, from, to, opts)
      hash[user.id] = UserReportDecorator.new(user, user_report)
      hash
    end
  end

  def get_attribute_filter_query(col_name)
    return true unless attribute_value_filter.valid?

    relational_filter_operator =  attribute_value_filter.relational_operator
    sanitized_filter_value = ActiveRecord::Base.connection.quote(@opts[:attribute_filter_value])
    return "#{col_name} #{relational_filter_operator} #{sanitized_filter_value}"
  end

  class AttributeValueFilter
    attr_accessor :filter_key, :filter_value

    RELATIONAL_OPERATOR_HASH = {
        eq_to: '=',
        gt: '>',
        gt_or_eq_to: '>=',
        lt: '<',
        lt_or_eq_to: '<='
    }.freeze

    def initialize(filter_key, filter_value)
      @filter_key = filter_key
      @filter_value = filter_value
    end

    def relational_operator
      RELATIONAL_OPERATOR_HASH[@filter_key]
    end

    def valid?
      @filter_value.present? &&
          @filter_key.present? &&
          relational_operator.present?
    end

    # Check if relation (determined by relational_operator) between the passed in number and @filter_value is true.
    def is_valid_for?(number)
      # The '=' operator works for sql, but not for checking logical relations between two numbers. So change it to '=='.
      rel_operator = (relational_operator == '=') ? '==' : relational_operator
      number.send(rel_operator, @filter_value)
    end

    def show_records_with_zero_value?
      valid? ? is_valid_for?(zero = 0) : false
    end
  end

  class UserReportDecorator
    attr_accessor :user, :report

    def initialize(user, report)
      @user = user
      @report = report
      @attrs = {}
    end

    def [](key)
      respond_to?(key) ? send(key) : @attrs[key]
    end

    def []=(key, value)
      @attrs[key] = value
    end

    def id
      user.present? ? user.id : report.user_id
    end

    def sent_recognitions
      report.sent_recognition_count
    end

    def received_recognitions
      report.received_recognition_count
    end

    def sent_approvals
      report.sent_approval_count
    end

    def received_approvals
      report.received_approval_count
    end

    def points
      report.points
    end
  end
end
