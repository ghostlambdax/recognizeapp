# accepts an array of objects
# that respond to #date and #count
# @opts = {
#   interval: :daily # can be :daily, :weekly representing how often there should be data points
#   reverse_chrono: true #sorts it in reverse chronological order, DEFAULT
# }
class GraphData
  include Enumerable
  include BenchmarkLogger

  attr_accessor :data, :sorted_data, :opts, :interval

  # https://database.guide/yearweek-examples-mysql/
  YEARWEEK_MODE = 1

  def self.load(data, interval)
    return new([]) unless data.size > 0
    klass = data.respond_to?(:limit) ? data.limit(1).first.class : data[0].class
    table = klass.table_name
    if data.respond_to?(:pluck)
      set = data.except(:select).select("distinct YEARWEEK(#{table}.created_at, #{YEARWEEK_MODE}) as date, count(*) as count").group("YEARWEEK(#{table}.created_at, #{YEARWEEK_MODE})").order("#{table}.created_at desc")
    else
      ids = data.map(&:id)
      set = klass.where(id: ids).select("distinct YEARWEEK(#{table}.created_at, #{YEARWEEK_MODE}) as date, count(*) as count").group("YEARWEEK(#{table}.created_at, #{YEARWEEK_MODE})").order("created_at desc")
    end
    new(set, interval: :weekly)
  end

  def initialize(data, opts={})
    @data, @sorted_data = data, []
    @opts = get_opts(opts)
    @interval = @opts[:interval]
    bmlog("SORTING(#{data[0].class})"){sort! if data.present?}
  end

  DEFAULT_OPTS = {
    interval: :daily,
    reverse_chrono: true
  }.freeze
  def get_opts(opts)
    DEFAULT_OPTS.merge(opts)
  end

  def sort_reverse?
    opts[:reverse_chrono].present?
  end

  def each(&block)
    @sorted_data.each do |datum|
      block.call(datum)
    end
  end

  def interval
    case opts[:interval]
    when :daily
      # daily data is a date value, so we need to move interval
      # by the number of seconds in a day
      1.day
    when :weekly
      # weekly data is represented in YYYYWK format, see mysql YEARWEEK
      # so we only need to move interval by one
      1
    end
  end

  def to_array
    collect{|d| [d.timestamp, d.count]}
  end

  def self.split_yearweek(yearweek)
    if yearweek.kind_of?(Date)
      year, week = yearweek.year, yearweek.cweek
    else
      m = yearweek.to_s.match(/^([0-9]{4})([0-9]{2})$/)
      year, week = m[1].to_i, m[2].to_i
    end
    return year, week
  end

  YEARWEEK_FMT = "%Y%W"
  def self.add_interval(date, value)
    # date can be YYYYWW or Date object
    unless date.kind_of?(Date)
      year, week = split_yearweek(date)
      newweek = week + value

      if newweek == 0
        year -= 1
        if(fifty_three_week_years.include?(year))
          newweek = 53
        else
          newweek = 52
        end
      elsif newweek == 53 || newweek == 54
        year += 1
        newweek = 1
      end

      newweek = newweek.to_s.rjust(2, '0')
      return "#{year}#{newweek}".to_i
    else
      return date + value
    end
  end

  def self.subtract_interval(yearweek, value)
    add_interval(yearweek, -value)
  end

  # Some years have 53 weeks and since we use mysql YEARWEEK
  # we need to account for this when we add/subtract intervals 
  def self.fifty_three_week_years
    @fifty_three_week_years ||= begin
      from_year = 2000 # Recognize was established 2012, so its safe default.
      to_year = Date.current.year + 1
      (from_year..to_year).select do |year|
        Company.select("YEARWEEK('#{year}-12-31, #{YEARWEEK_MODE}') as yw").limit(1).first.yw.to_s.match(/53$/)
      end
    end
  end

  protected
  # fill in the gaps of dates
  def sort!
    if sort_reverse?
      sort_reverse!
    else
      raise "not implemented yet"
    end
  end

  def sort_reverse!
    temp_sorted_data = []

    bmlog("SORTING TEMP DATA", skip: true) do
      temp_sorted_data = data.sort { |a, b| b.date <=> a.date }
    end
    return [] unless temp_sorted_data.present?

    date = temp_sorted_data[0].date
    end_date = temp_sorted_data.last.date
    index = 0
    bmlog("ZERO FILLING", skip: true) {

      while(date >= end_date)
        bmlog("ZEROFILL: #{date}", skip: true) {
          if date == temp_sorted_data[index].date
            # does previous week(in set, not in time) have a data point, if not, zero fill it
            next_date = GraphData.add_interval(date, self.interval)
            if sorted_data.present? and sorted_data.last.date != next_date
              sorted_data << GraphDataPoint.new(date: next_date, count: 0, opts: opts)
            end

            sorted_data << GraphDataPoint.new(date: temp_sorted_data[index].date, count: temp_sorted_data[index].count, opts: opts)
            index += 1
          else
            # only zero fill one point
            unless sorted_data.last.count == 0
              sorted_data << GraphDataPoint.new(date: date, count: 0, opts: opts)
            end
          end
          date = GraphData.subtract_interval(date, self.interval)
        }
      end
    }
    return sorted_data
  end

  class GraphDataPoint < RecognizeOpenStruct
    def timestamp
      if opts[:interval] == :weekly
        year, week = GraphData.split_yearweek(self.table[:date])
        # For some reason, we can get week == 53, adjust in those cases.
        if week == 53
          year += 1
          week = 1
        end

        # Here `-1` is used to get the last day of the particular year week.
        return Date.commercial(year, week, -1).to_time.to_i*1000
      else
        return self.table[:date].to_time.to_i*1000
      end
    end
  end

end

