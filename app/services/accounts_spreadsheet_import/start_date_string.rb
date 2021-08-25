# frozen_string_literal: true

#
# Used to get equivalent DateTime object from the birthday date string.
#
module AccountsSpreadsheetImport
  class StartDateString < DateString
    def valid_date_formats
      {
        dashed_yyyy_mm_dd: { regex: international_date_regex, template: international_date_template },
        slashed_mm_dd_yyyy: { regex: %r{^\d{1,2}\/\d{1,2}\/\d{4}$}, template: "%m/%d/%Y" }
      }
    end
  end
end
