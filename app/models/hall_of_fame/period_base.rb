class HallOfFame::PeriodBase
  include IntervalHelper

  attr_accessor :company, :user, :reference_time, :opts, :sort_by

  def self.winners(company, user, reference_time, opts={})
    new(company, user, reference_time, opts).winners
  end

  def initialize(company, user, reference_time, opts)
    @company = company
    @user = user
    @reference_time = reference_time
    @opts = opts
    @sort_by = opts[:sort_by] || default_sort_by
  end

  def default_sort_by
    # company.hide_points ? :received_recognitions : :points
    :received_recognitions
  end

  def interval
    Interval.new(self.class.const_get("INTERVAL"))
  end

  def start_time
    interval.start(time: reference_time)
  end

  def end_time
    interval.end(time: reference_time)
  end

  def report_options
    # For now, have HoF specify non-anniversary badges
    # We may need to expand this support to other parts of the system 
    # and/or make it default behavior, but to limit potential impact
    # only specify non-anniversary badges here
    badge_id = opts[:badge_id] || company.company_badges.recognitions.pluck(:id)
    { badge_id: badge_id, team_id: opts[:team_id], received_recognitions_only: true, user_status_scope: :not_disabled }
  end

  def winners
    key = "HoF::PeriodBase-#{sort_by}-#{start_time.to_date.to_s}-#{end_time.to_date.to_s}-#{opts[:badge_id]}-#{opts[:team_id]}"
    full_key = HallOfFame.cache_key(company, I18n.locale, key)
    Rails.cache.fetch(full_key) do
      Rails.logger.debug "[HALLOFFAME] #{self.class}#winners - #{full_key}"
      report = Report::Company.new(company, start_time, end_time, report_options)
      HallOfFame::Group.new(label, report, {sort_by: sort_by})
    end
  end
  
end
