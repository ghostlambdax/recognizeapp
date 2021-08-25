# frozen_string_literal: true

#
# Represents the uploaded data sheet(its innards).
# This class is different from `DataSheetFile` class such that `DataSheetFile` deals with basic file related
# activities, where as `DataSheet` deals with any activities that needs peeking inside the sheet content.
#
module AccountsSpreadsheetImport
  class DataSheet
    include ActiveModel::Model
    attr_accessor :data_sheet_file
    attr_reader :styles

    TEAM_DELIMITER = ","
    ROLE_DELIMITER = ","

    delegate :company, to: :data_sheet_file
    delegate :row, to: :sheet

    def initialize(attributes = {})
      super
    end

    def schema
      @schema ||= AccountsSpreadsheetImport::HeaderRowSchemaResolver.schema(data_sheet_file)
    end

    def sheet
      @sheet ||= begin
        xlsx = Roo::Spreadsheet.open(data_sheet_file.path, extension: data_sheet_file.extension)
        xlsx.sheet(sheet_number)
      end
    end

    def last_row_index
      sheet.last_row
    end

    def header_row_index
      begin
        sheet.first_row
      rescue => e
        Rails.logger.debug "Caught exception on AccountsSpreadsheetImport::DataSheet#header_row_index"
        Rails.logger.debug "Data Sheet File: #{data_sheet_file.attributes}" rescue nil
        Rails.logger.debug "Data Sheet File path: #{data_sheet_file.path}" rescue nil
        Rails.logger.debug "Data Sheet File ext: #{data_sheet_file.extension}" rescue nil
        Rails.logger.debug "csv's in tmp folder: #{Dir["/tmp/**/*.csv"].join(", ")}" rescue nil
        Rails.logger.debug "end of debug"
        raise e
      end
    end

    def header_row
      @header_row ||= sheet.row(header_row_index)
    end

    def sheet_number
      0
    end

    def team_delimiter
      TEAM_DELIMITER
    end

    def role_delimiter
      ROLE_DELIMITER
    end

    def consider_custom_fields?
      company.settings.sync_custom_fields? && company.custom_field_mappings.present?
    end

    # Returns list of AccountsSpreadSheetImport::HeaderSchemaResolver::HeaderCell object that are ordered by column_index.
    def header_cells_in_data_sheet_file
      schema.header_cells.select(&:present_in_sheet).sort_by(&:column_index)
    end

    def custom_field_provider_headers
      @custom_field_provider_keys ||= company.custom_field_mappings.provider_keys
    end

    def generic_header?(header)
      generic_headers = HeaderAlias.supported_headers
      generic_headers.find { |valid_header| HeaderAlias.matches?(valid_header, header) }.present?
    end

    def custom_field_header?(header)
      custom_field_headers = custom_field_provider_headers
      custom_field_headers.find { |custom_field_header| custom_field_header == header }.present?
    end

    def valid_header?(header)
      generic_header?(header) || custom_field_header?(header)
    end

    #
    # Used for errors or warnings that was encountered while processing the data_sheet.
    # - status:
    #   - Either 'Saved but requires attention' or 'Failed'
    # - remarks
    #   - Reason to back the `status`.
    #
    def remarks_headers
      %w[Status Remarks]
    end

    def total_record_rows
      last_row_index - header_row_index
    end

    def blank?
      last_row_index.nil?
    end

    # Check if data sheet has account record rows, and not only header row.
    def account_record_rows?
      (last_row_index - header_row_index).positive?
    end

    def headers_match?(alias_header, expected_header, opts = {})
      HeaderAlias.matches?(expected_header, alias_header, opts)
    end

    # Expected(but not strictly)
    def expected_start_date_format
      "%m/%d/%Y"
    end

    # Expected(but not strictly)
    def expected_birthday_format
      "%m/%d"
    end

    CELL_COLORS = { green: "beebc6", yellow: "ffffc5", red: "ffbfc7" }.freeze
    def self.custom_styles(worksheet)
      custom_styles = {}
      custom_styles[:cells_saved] = worksheet.styles.add_style(bg_color: CELL_COLORS[:green])
      custom_styles[:cells_requiring_attention] = worksheet.styles.add_style(bg_color: CELL_COLORS[:yellow])
      custom_styles[:cells_trigerring_failure] = worksheet.styles.add_style(bg_color: CELL_COLORS[:red])
      custom_styles[:bold] = worksheet.styles.add_style(b: true)
      custom_styles[:bold_and_italic] = worksheet.styles.add_style(b: true, i: true)
      custom_styles[:horizontal_center_and_bold] = worksheet.styles.add_style(b: true, alignment: {horizontal: :center})
      custom_styles[:date_time] =  worksheet.styles.add_style(num_fmt: Axlsx::NUM_FMT_YYYYMMDDHHMMSS)
      custom_styles
    end
  end
end
