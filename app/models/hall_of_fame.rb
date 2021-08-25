class HallOfFame
  attr_reader :company, :user, :interval_code, :opts

  PER_ROW = 10
  CACHE_KEY_PREFIX = "HallOfFame-2.7"

  def self.whitelist
    # list to allow users to access hall of fame before enabling for
    # entire company
    ["bruce.rioch@metrobank.plc.uk.not.real.tld"]
  end

  def initialize(company, user, opts={})
    @company = company
    @user = user
    @interval_code = opts[:interval] || Interval::MONTHLY
    @opts = opts
  end

  def current_winners_grouped_by_period
    [
      winners_by_year,
      winners_by_quarter,
      winners_by_month,
      winners_by_week
    ]   
  end

  def winners_by_year
    time = opts[:time] || Time.current.last_year
    HallOfFame::ByYear.winners(company, user, time, opts)
  end

  def winners_by_quarter
    time = opts[:time] || Time.current.last_quarter
    HallOfFame::ByQuarter.winners(company, user, time, opts)
  end

  def winners_by_month
    time = opts[:time] || Time.current.last_month
    HallOfFame::ByMonth.winners(company, user, time, opts)
  end

  # Time.current.last_week always go to the beginning of the week
  # which is not desirable because the diff between current and then > 1.week
  # and so we wont render "last week"
  def winners_by_week
    time = opts[:time] || (Time.current - 1.week)
    HallOfFame::ByWeek.winners(company, user, time, opts)
  end

  def badges
    company.company_badges.recognitions
  end

  def by_badge
    return HallOfFame::ByBadge.winners(company, user, Badge.find(opts[:badge_id]), interval_code, opts) if opts[:badge_id].present?

    badges.inject({}) do |hash, badge|
      Rails.logger.debug "[HALLOFFAME] HallOfFame#bybadge - Badge#{badge.id} - #{badge.short_name}"
      hash[badge] = HallOfFame::ByBadge.winners(company, user, badge, interval_code, opts)
      hash
    end
  end

  def teams
    company.teams
  end

  def by_team
    return HallOfFame::ByTeam.winners(company, user, Team.find(opts[:team_id]), interval_code, opts) if opts[:team_id].present?

    teams.inject({}) do |hash, team|
      Rails.logger.debug "[HALLOFFAME] HallOfFame#byteam - Team#{team.id} - #{team.name}"
      hash[team] = HallOfFame::ByTeam.winners(company, user, team, interval_code, opts)
      hash
    end
  end

  def self.cache_key(company, locale, key)
    "#{HallOfFame::CACHE_KEY_PREFIX}-#{locale}-#{company.id}-#{key}"
  end

  def self.reset_cache!(company)
    company.users.pluck(:locale).uniq.reject(&:blank?).each do |locale|
      Rails.cache.delete_matched("#{HallOfFame.cache_key(company, locale, '')}*")
    end
  end
end
