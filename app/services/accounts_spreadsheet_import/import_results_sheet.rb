# frozen_string_literal: true

# Used to create spreadsheet that contains problematic records that either failed to save or were saved but require
# attention. The file is to be used by end-user as a feedback for accounts spreadsheet import. #
require 'axlsx'

module AccountsSpreadsheetImport
  class ImportResultsSheet
    attr_reader :data_sheet, :account_records, :import_summary, :data_sheet_styles

    def initialize(data_sheet, account_records, import_summary)
      @data_sheet = data_sheet
      @account_records = account_records
      @import_summary = import_summary
    end

    #
    # Returns File obj.
    #
    def create
      package = Axlsx::Package.new
      workbook = package.workbook
      workbook.add_worksheet(name: "Sheet 1") do |worksheet|
        build_data_sheet_styles(worksheet)

        add_summary_section(worksheet)

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

    private

    def add_summary_section(worksheet)
      worksheet.merge_cells "A1:B1" # This cell will contain the term "IMPORT SUMMARY"
      summary_rows_with_style.each do |row_with_style|
        worksheet.add_row *row_with_style
      end
      worksheet.add_row [] # Add empty row for visual clarity to distinguish the next section.
    end

    def add_attribute_headers(worksheet)
      worksheet.add_row [problematic_records_instruction], style: [data_sheet_styles[:bold_and_italic]]
      headers = data_sheet.header_cells_in_data_sheet_file.map(&:content) + data_sheet.remarks_headers
      worksheet.add_row headers, style: ([data_sheet_styles[:bold]] * headers.length)
    end

    def add_problematic_records_rows(worksheet)
      problematic_records.each do |record|
        cell_contents_for_row = cell_contents_for_record(record) + cell_contents_for_remarks(record)
        cell_stylings_for_row = cell_stylings_for_record(record) + cell_stylings_for_remarks
        worksheet.add_row cell_contents_for_row, style: cell_stylings_for_row
      end
    end

    def whitelisted_summary_attributes
      %i[started_at
        importing_actor_signature
        completed_at
        total_records_count
        successful_records_count
        failed_records_count
        saved_but_require_attention_records_count
        ]
    end

    def summary_rows_with_style
      row_with_style_arr = []
      row_with_style_arr << [ ["IMPORT SUMMARY"], style: [data_sheet_styles[:horizontal_center_and_bold]] ]

      import_summary.each do |key, value|
        next unless key.in? whitelisted_summary_attributes.map(&:to_s)

        item_attribute = key.to_s.humanize
        item_value = value.to_s

        if key == "importing_actor_signature" # Special case.
          item_attribute = "Importer"
          item_value = ActorConcern.actor_from_signature(value).label
        end

        row = [item_attribute, item_value]
        style = [data_sheet_styles[:bold], nil]
        row_with_style_arr << [row, style: style]
      end
      row_with_style_arr
    end

    def cell_contents_for_record(account_record)
      cell_contents = []
      upserted_attributes.each do |attribute|
        attribute_value = account_record.send(attribute)
        cell_contents << begin
          case attribute
            when :team_names
              attribute_value.is_a?(Array) ? attribute_value.join(data_sheet.team_delimiter) : attribute_value
            when :role_names
              attribute_value.is_a?(Array) ? attribute_value.join(data_sheet.role_delimiter) : attribute_value
            when :start_date
              # Revert back start_date to what was obtained from the data sheet, if it was parsed to DateTime earlier.
              attribute_value.is_a?(DateTime) ? attribute_value.strftime(data_sheet.expected_start_date_format) : attribute_value
            when :birthday
              # Revert back birthday to what was obtained from the data sheet, if it was parsed to DateTime earlier.
              attribute_value.is_a?(DateTime) ? attribute_value.strftime(data_sheet.expected_birthday_format) : attribute_value
            else
              attribute_value
          end
        end
      end
      cell_contents
    end

    def cell_contents_for_remarks(account_record)
      cell_contents = []
      # Status column cell content
      cell_contents << account_record.status.to_s.humanize
      # Remarks column cell content
      cell_contents << begin
        error_messages = account_record.errors.select { |_key, message| message.present? }.map { |_key, message| message }
        warning_messages = account_record.warnings.select { |_key, message| message.present? }.map { |_key, message| message }
        error_messages.concat(warning_messages).join(" ")
      end
      cell_contents
    end

    def upserted_attributes
      data_sheet_schema.attributes_to_upsert
    end

    def build_data_sheet_styles(worksheet)
      @data_sheet_styles ||= AccountsSpreadsheetImport::DataSheet.custom_styles(worksheet)
    end

    def problematic_records_instruction
      has_records_with_error = problematic_records.find { |account_record| account_record.errors.present? }
      has_records_with_warning = problematic_records.find { |account_record| account_record.warnings.present? }

      if has_records_with_error && has_records_with_warning
        'The following records either failed or were saved but require attention.'
      elsif has_records_with_error
        'The following records failed.'
      elsif has_records_with_warning
        'The following records were saved but require attention.'
      else
        ''
      end
    end

    def cell_stylings_for_record(account_record)
      stylings = []
      cell_length = upserted_attributes.length
      if account_record.errors.present?
        stylings = [data_sheet_styles[:cells_trigerring_failure]] * cell_length
      elsif account_record.warnings.present?
        stylings = [data_sheet_styles[:cells_requiring_attention]] * cell_length

        # Not all attributes are problematic. Mark attributes that weren't problematic as `cells_saved`.
        upserted_attributes.each do |attribute|
          if account_record.warnings[attribute].blank?
            index_of_key_value = upserted_attributes.index(attribute)
            stylings[index_of_key_value] = data_sheet_styles[:cells_saved]
          end
        end
      end
      stylings
    end

    def cell_stylings_for_remarks
      @cell_stylings_for_remarks ||= begin
        cell_length = data_sheet.remarks_headers.size
        [data_sheet_styles[:cells_saved]] * cell_length
      end
    end

    def problematic_records
      account_records.select { |account_record| account_record.errors.present? || account_record.warnings.present? }
    end

    def temp_file
      @temp_file ||= Tempfile.new([tmp_filename, ".xlsx"])
    end

    def tmp_filename
      @tmp_filename ||= "accounts_spreadsheet_import_results_#{data_sheet.data_sheet_file.company.domain}"
    end

    def data_sheet_schema
      data_sheet.schema
    end
  end
end
