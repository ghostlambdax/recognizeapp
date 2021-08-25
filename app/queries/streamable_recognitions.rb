class StreamableRecognitions
  # Order of badge is important because it is referenced in some places.
  BADGE_FILTERS = %w[anniversary recognition]

  attr_reader :current_user, :network, :company, :team_id, :filter_by

  def self.call(args)
    new(args).query
  end

  def initialize(args)
    extract_args args
  end

  def query
    scoped = filter_by_network_and_parameters
    scoped = scoped.approved.not_private
    scoped = scoped.includes(:badge)
    if company.settings.hide_disabled_users_from_recognitions?
      # When both recipients_active and sender_active scope applied, it fetched the recognitions having sender
      # active and at least one recipient active.
      scoped = scoped.recipients_active.sender_active
    end
    scoped.distinct
  end

  private

  def extract_args(args)
    @current_user = args[:user]
    @network = args[:network]
    @company = args[:company]
    @team_id = args[:team_id]
    @filter_by = (Array(args[:filter_by]) & badge_filters) || []
  end

  def filter_by_network_and_parameters
    # special handling for Recognize network or admins
    # there is a quirk when you view stream page as a non admin user on recognizeapp.com domain
    # we enter this conditional and will see all the system recognitions sent by the system user
    # to have consistency, and to not freak me out in the future when i log in as another recognizeapp
    # user, have a special condition for this
    records = recognitions_for_recognize_network_or_admins if is_admin_or_recognize_network?
    filter_by_parameters records
  end

  def filter_by_parameters(default_records)
    records = if team_id_present_and_valid?
      find_by_team_id
    else
      default_records || default_recognitions
    end
    records = find_by_badge(records) if filter_by.any?
    records
  end

  def find_by_team_id
    find_team&.recognitions
  end

  def find_by_badge(records)
    return records if filter_by.length == badge_filters.length

    records = records.includes(:badge)
    is_anniversary_query = filter_by.include?(badge_filters.first)
    records.where(badges: { is_anniversary: is_anniversary_query })
  end

  def recognitions_for_recognize_network_or_admins
    return find_by_user_company if is_same_network?

    find_by_network
  end

  # FIXME: Admin or Director can type any network in url and access the stream page but all the rendered links
  #        on that page point to the different company. Network verification has to be done to fix it.
  # Note: This query is used for recognize_network_or_admins only
  def find_by_network
    Company.where(domain: network).first.recognitions
  end

  # Note: This query is used for recognize_network_or_admins only
  def find_by_user_company
    current_user.company.recognitions
  end

  def is_admin_or_recognize_network?
    current_user && (current_user.admin? || network == "recognizeapp.com")
  end

  def is_same_network?
    network.casecmp?(current_user.network)
  end

  def default_recognitions
    Recognition.for_company(company) || Recognition.none
  end

  # FIXME: team_id could be any company's team. Need special handeling for team verification
  # so that to fetch recognitions from authoritative company's team only.
  def team_id_present_and_valid?
    team_id.present?
  end

  def find_team
    Team.find_from_recognize_hashid(team_id)
  end

  def badge_filters
    self.class::BADGE_FILTERS
  end
end
