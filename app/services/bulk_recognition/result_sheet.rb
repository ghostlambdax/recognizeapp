require 'axlsx'

module BulkRecognition
  class ResultSheet

    attr_reader :problematic_records

    ROW_HEADERS = ["Sender email", "Recipient email(s)", "Badge", "Message", "Point value (optional)", "Remarks"].freeze

    def initialize(problematic_records)
      @problematic_records = problematic_records
    end

    def create
      package = Axlsx::Package.new
      workbook = package.workbook
      workbook.add_worksheet(name: "Sheet 1") do |worksheet|
        if problematic_records.present?
          add_attribute_headers(worksheet)
          add_problematic_records_rows(worksheet)
        end
      end

      package.use_shared_strings = true
      # Write the data_sheet to file.
      package.serialize temp_file
      temp_file
    end

    def add_attribute_headers(worksheet)
      worksheet.add_row(ROW_HEADERS, style: worksheet.styles.add_style(b: true))
    end

    def add_problematic_records_rows(worksheet)
      style = row_style(worksheet)
      problematic_records.each do |record|
        worksheet.add_row record, style: style
      end
    end

    def row_style(worksheet)
      ([nil] * ROW_HEADERS.count).tap do |styles|
        # for the last "remarks" cell
        styles[-1] = worksheet.styles.add_style(alignment: {wrap_text: true})
      end
    end

    def temp_file
      @temp_file ||= Tempfile.new([tmp_file_basename, ".xlsx"])
    end

    def tmp_file_basename
      @tmp_file_basename ||= "bulk_recognizer_results"
    end
  end
end
