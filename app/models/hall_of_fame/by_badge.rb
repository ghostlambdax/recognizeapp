class HallOfFame::ByBadge
  attr_accessor :company, :user, :badge, :interval, :opts

  def self.winners(company, user, badge, interval_code, opts={})
    new(company, user, badge, interval_code, opts).winners
  end

  def initialize(company, user, badge, interval_code, opts)
    @company = company
    @user = user
    @badge = badge
    @interval = Interval.new(interval_code)
    @opts = opts
  end

  def start_date
    @start_date ||= opts[:start_date].present? ?  Time.zone.parse(opts[:start_date]) : Time.current
  end

  def end_date
    # return company.created_at
    @end_date ||= Recognition.where(badge_id: badge.id).minimum(:created_at) || Time.current
  end

  def winners

    date = start_date
    groups = []
    while(date > end_date)
      Rails.logger.debug "[HALLOFFAME] ByBadge#winners - #{date}"
      date = interval.shift(time: date, shift: -1)
      if groups.length < HallOfFame::PER_ROW
        winning_group = grouper.winners(company, user, date, badge_id: badge.id, team_id: opts[:team_id])
        groups << winning_group if winning_group.has_winners?
      else
        Rails.logger.debug "[HALLOFFAME] - hit max groups, making date = end_date #{date} - #{end_date}"
        date = end_date
      end
    end
    return groups
  end

  def grouper
    case 
    when interval.weekly?
      HallOfFame::ByWeek
    when interval.monthly?
      HallOfFame::ByMonth
    when interval.quarterly?
      HallOfFame::ByQuarter
    when interval.yearly?
      HallOfFame::ByYear
    else
      raise "not supported"
    end
  end

end
