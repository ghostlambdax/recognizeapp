class HallOfFame::ByTeam
  attr_accessor :company, :user, :team, :interval, :opts

  def self.winners(company, user, team, interval_code, opts={})
    new(company, user, team, interval_code, opts).winners
  end

  def initialize(company, user, team, interval_code, opts)
    @company = company
    @user = user
    @team = team
    @interval = Interval.new(interval_code)
    @opts = opts
  end

  def start_date
    opts[:start_date].present? ?  Time.zone.parse(opts[:start_date]) : Time.current
  end

  def end_date
    return company.created_at
  end

  def winners
    date = start_date
    groups = []
    while(date > end_date)
      Rails.logger.debug "[HALLOFFAME] ByTeam#winners - #{date}"
      date = interval.shift(time: date, shift: -1)
      if groups.length < HallOfFame::PER_ROW
        winning_group = grouper.winners(company, user, date, team_id: team.id, badge_id: opts[:badge_id])
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
