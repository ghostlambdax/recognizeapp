class DateRange

  attr_reader :start_time, :end_time

  def initialize(from, to = nil)
    @start_time = parse_start_time(from)
    @end_time = parse_end_time(to)
  end

  def parse_start_time(time)
    parse(time).beginning_of_day
  end

  def parse_end_time(time)
    parse(time).end_of_day
  end

  def range
    (start_time..end_time)
  end

  def start_date
    start_time.to_date
  end

  def end_date
    end_time.to_date
  end

  def parse(value)
    return value.in_time_zone if value.kind_of?(Time)
    return Time.zone.at(value.to_i) if is_integer_value?(value)
    # TODO support for various date time format
    # failing "21:58:06 Apr 29, 2015 PDT"
    Time.zone.parse(value.to_s) || Time.current
  end

  def is_integer_value?(value)
    value.kind_of?(Integer) || (value.kind_of?(String) && value.to_i.to_s == value)
  end
end
