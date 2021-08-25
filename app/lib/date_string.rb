#
# Used by to get DateTime object from (user fed) date string.
#
class DateString

  attr_reader :date_str

  def self.to_datetime(date_str)
    new(date_str).datetime_object
  end

  def initialize(date_str)
    @date_str = date_str.to_s
  end

  #
  # The method should return a hash with one or more date formats as shown below. The keys of the hash are solely
  # identifiers and can use any name. However, the keys inside the values should strictly be named `regex` and
  # `template`, and hold relevant values.
  # Eg:
  #   {
  #     slashed_yyyy_mm_dd: { regex: %r{^\d{4}\/\d{1,2}\/\d{1,2}$}, template: "%Y/%m/%d" },
  #     slashed_mm_dd_yyyy: { regex: %r{^\d{1,2}\/\d{1,2}\/\d{4}$}, template: "%m/%d/%Y" }
  #   }
  #
  def valid_date_formats
    raise "Must be implemented by subclass"
  end

  def datetime_object
    return nil if date_str.blank?
    valid_template_format = valid_date_format_match && valid_date_format_match[:template]
    return nil if valid_template_format.blank?
    DateTime.strptime("#{date_str} 05:00 PDT", valid_template_format + " %H:%M %Z")
  end

  def matches_template_format?(format)
    DateTime.strptime(date_str, format)
  rescue ArgumentError
    nil
  end

  def matches_regex_format?(format)
    date_str.match(format)
  end

  #
  # NOTE: Rationale for checking for regex match as well as template match -
  #
  # Despite trying to implement checking for validity of date solely by checking a date's parsability against the
  # expected date templates, it was pain in the neck to do so due to `DateTime.strptime` auto-magical behavior, which
  # lacked predictability. Therefore, in addition to checking for parsability, checking for regexp is also done.
  #
  # Examples of `DateTime.strptime`'s peculiarities:
  #     DateTime.strptime("88/12/21", "%Y/%m/%d")
  #       Sun, 21 Dec 0088 00:00:00 +0000
  #
  #     DateTime.strptime("12/21/1988", "%m/%d/%y")
  #       Sat, 21 Dec 2019 00:00:00 +0000
  #     DateTime.strptime("1988/12/21", "%y/%m/%d")
  #       *** ArgumentError Exception: invalid date
  #
  def matches_both_formats?(formats)
    matches_regex_format?(formats[:regex]) && matches_template_format?(formats[:template])
  end

  def valid_date_format_match
    valid_date_formats.values.detect { |formats| matches_both_formats?(formats) }
  end

  #
  # NOTE: Even if international date template (YYYY-MM-DD) might not be an expected format for a date column in the
  # spreadsheet, its use is necessary!
  #
  # TLDR: When the spreadsheet is parsed by ruby, if the cell containing start_date is formatted as date (not text),
  # the date is merely a date object(without any formatting).
  #
  # Description: When `roo` reads from excel spreadsheet, dates (whichever format they are in excel) are returned in
  # format YYYY-MM-DD(the international/official standard date format); this is because <date_object>.to_s returns a
  # YYYY-MM-DD formatted date string.  Example: A date object in excel formatted (to be seen) as MM/DD/YYYY, when
  # converted to equivalent ruby date object string would return YYYY-MM-DD.
  #
  # On contrary, a date can be formatted as text (not date) in the spreadsheet. In this case, the date(or rather text)
  # is read AS IS (in the excelsheet). Checking for validity of the date against the expected date template formats
  # needs to done.
  #
  #
  def international_date_template
    "%Y-%m-%d"
  end

  def international_date_regex
    /^\d{4}-\d{1,2}-\d{1,2}$/
  end

end
