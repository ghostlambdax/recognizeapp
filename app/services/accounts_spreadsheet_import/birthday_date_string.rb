# frozen_string_literal: true

#
# Used to get equivalent DateTime object from the birthday date string.
#
module AccountsSpreadsheetImport
  class BirthdayDateString < DateString
    def initialize(date_str)
      super
      massage_if_required
    end

    def massage_if_required
      slashed_mm_dd_regex = valid_date_formats[:slashed_mm_dd][:regex]
      return unless matches_regex_format?(slashed_mm_dd_regex)

      @date_str = "#{@date_str}/#{User::BIRTHYEAR}"
    end

    def valid_date_formats
      {
        dashed_yyyy_mm_dd: { regex: international_date_regex, template: international_date_template },
        slashed_yyyy_mm_dd: { regex: %r{^\d{4}\/\d{1,2}\/\d{1,2}$}, template: "%Y/%m/%d" },
        slashed_mm_dd_yyyy: { regex: %r{^\d{1,2}\/\d{1,2}\/\d{4}$}, template: "%m/%d/%Y" },
        slashed_mm_dd: { regex: %r{^\d{1,2}\/\d{1,2}$}, template: "%m/%d" } # This format is redundant due to `massage_if_required` method logic.
      }
    end
  end
end
