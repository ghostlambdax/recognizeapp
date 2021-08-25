class Interval
  include IntervalHelper

  RESET_INTERVALS = {
    DAILY=0 => "daily",
    WEEKLY=1 => "weekly",
    MONTHLY=2 => "monthly",
    QUARTERLY=3 => "quarterly",
    YEARLY=4 => 'yearly'
  }

  NULL_INTERVAL = { NULL=nil => 'None' }
  TRIMESTER_INTERVAL = { TRIMESTER=5 => 'trimester' }
  RESET_INTERVALS_WITH_NULL = RESET_INTERVALS.merge(NULL_INTERVAL)
  RESET_INTERVALS_WITH_TRIMESTER = RESET_INTERVALS.merge(TRIMESTER_INTERVAL)
  RESET_INTERVALS_WITH_TRIMESTER_AND_NULL = RESET_INTERVALS_WITH_TRIMESTER.merge(NULL_INTERVAL)

  CUSTOM = -1

  attr_reader :interval, :interval_code

  def self.reset_intervals
    RESET_INTERVALS
  end

  def self.reset_intervals_with_null
    RESET_INTERVALS_WITH_NULL
  end

  def self.intervals_ordered_by_weight(direction: :asc, include_null_interval: true)
    intervals = [Interval.daily, Interval.weekly, Interval.monthly, Interval.quarterly, Interval.trimester, Interval.yearly]
    intervals << Interval.null if include_null_interval
    intervals = intervals.reverse if direction == :desc
    intervals
  end

  def initialize(interval_code)
    @interval_code = interval_code.nil? ? nil : interval_code.to_i
  end

  def ==(other)
    return false unless other.is_a? self.class

    other.interval_code == self.interval_code
  end

  def >(other)
    ordered_intervals = Interval.intervals_ordered_by_weight(direction: :asc, include_null_interval: false)
    index_of_self = ordered_intervals.index(self)
    index_of_other = ordered_intervals.index(other)
    index_of_self > index_of_other
  end

  def <(other)
    !(self == other || self > other)
  end

  def to_i
    interval_code
  end

  def name
    RESET_INTERVALS_WITH_TRIMESTER.fetch(to_i, "No Limit")
  end

  def interval
    RESET_INTERVALS_WITH_TRIMESTER[interval_code]
  end

  def custom?
    interval_code == CUSTOM
  end

  def daily?
    interval_code == DAILY
  end

  def weekly?
    interval_code == WEEKLY
  end

  def monthly?
    interval_code == MONTHLY
  end

  def trimester?
    interval_code == TRIMESTER
  end

  def quarterly?
    interval_code == QUARTERLY
  end

  def yearly?
    interval_code == YEARLY
  end

  def noun(prefix: nil)
    if prefix
      reset_interval_noun(self, prefix)
    else
      reset_interval_noun(self)
    end
  end

  def prefixed_adverb(prefix: nil)
    if prefix
      reset_interval_adverb_with_prefix(self, prefix)
    else
      reset_interval_adverb(self)
    end
  end

  def null?
    interval_code == NULL
  end

  def shift(opts={})
    time = opts[:time] || Time.current
    shift_by = opts[:shift] || 0
    case
    when daily?
      time + shift_by.days
    when weekly?
      time + shift_by.weeks
    when monthly?
      time + shift_by.months
    when trimester?
      time + (4 * shift_by).months
    when quarterly?
      time + (3 * shift_by).months
    when yearly?
      time + shift_by.years
    end
  end

  def start(opts={})
    start_or_end("beginning", opts)
  end

  def end(opts={})
    start_or_end("end", opts)
  end

  def current(opts={})
    opts[:time] ||= Time.current
    shift(opts)
  end

  def upto_now(opts={})
    as_text = opts.delete(:as_text)
    start_time = start(opts)
    current_time = current(opts)
    return start_time..current_time unless as_text

    if daily?
      "Till #{current_time.strftime("%l:%M %P")}"
    elsif start_time.to_date == current_time.to_date
      "#{start_time.strftime("%b %d, %Y")} till #{current_time.strftime("%l:%M %P")}"
    else
      "#{start_time.strftime("%b %d, %Y")} to #{current_time.strftime("%b %d, %Y")}"
    end
  end

  def start_or_end(which, opts={})
    opts[:time] ||= Time.current
    time = shift(opts)
    case 
    when daily?
      time.send("#{which}_of_day")
    when weekly?
      time.send("#{which}_of_week")
    when monthly?
      time.send("#{which}_of_month")
    when trimester?
      send("#{which}_of_trimester", time)
    when quarterly?
      time.send("#{which}_of_quarter")
    when yearly?
      time.send("#{which}_of_year")
    end
  end

  class << self
    def daily
      Interval.new(Interval::DAILY)
    end

    def weekly
      Interval.new(Interval::WEEKLY)
    end

    def monthly
      Interval.new(Interval::MONTHLY)
    end

    def quarterly
      Interval.new(Interval::QUARTERLY)
    end

    def trimester
      Interval.new(Interval::TRIMESTER)
    end

    def yearly
      Interval.new(Interval::YEARLY)
    end

    def null
      Interval.new(Interval::NULL)
    end

    def custom
      Interval.new(Interval::CUSTOM)
    end

    def conversion_map
      @@conversion_map ||= {
        Interval::YEARLY => {
          Interval::TRIMESTER => 3,
          Interval::QUARTERLY => 4,
          Interval::MONTHLY => 12,
          Interval::WEEKLY => 52,
          Interval::DAILY =>365
        },
        Interval::TRIMESTER => {
          Interval::MONTHLY => 4,
          Interval::WEEKLY => 17,
          Interval::DAILY => 122
        },
        Interval::QUARTERLY => {
          Interval::MONTHLY => 3,
          Interval::WEEKLY => 13,
          Interval::DAILY => 92
        },
        Interval::MONTHLY => {
          Interval::WEEKLY => 4,
          Interval::DAILY => 31         
        },
        Interval::WEEKLY => {
          Interval::DAILY => 7         
        }
      }
    end

    def conversion_factor(from, to)
      if from == to
        1
      elsif from > to
        conversion_map[from.to_i][to.to_i]
      else
        -1*conversion_map[to.to_i][from.to_i]
      end
    end
  end

  def beginning_of_trimester(time)
    first_trimester_month = [9, 5, 1].detect { |m| m <= time.month }
    time.beginning_of_month.change(month: first_trimester_month)
  end

  def end_of_trimester(time)
    last_trimester_month = [4, 8, 12].detect { |m| m >= time.month }
    time.beginning_of_month.change(month: last_trimester_month).end_of_month
  end
end
