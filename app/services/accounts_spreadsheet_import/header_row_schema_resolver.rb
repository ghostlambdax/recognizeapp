# frozen_string_literal: true

module AccountsSpreadsheetImport
  class HeaderRowSchemaResolver
    attr_accessor :data_sheet_file

    def self.schema(data_sheet_file)
      new(data_sheet_file).schema
    end

    def initialize(data_sheet_file)
      @data_sheet_file = data_sheet_file
      @schema = HeaderRowSchema.new(company)
    end

    delegate :company, to: :data_sheet_file

    def schema
      header_cells_found = parse_headers

      user_attributes_absent_in_header_row = begin
        user_attributes_present_in_header_row = header_cells_found.select(&:is_supported_header).map(&:user_attribute)
        supported_attributes - user_attributes_present_in_header_row
      end

      user_attributes_absent_in_header_row.each do |user_attribute|
        @schema.add HeaderCell.new(user_attribute: user_attribute.to_sym, present_in_sheet: false, column_index: nil, content: nil, is_supported_header: false)
      end

      header_cells_found.select(&:is_supported_header).each do |header_cell|
        @schema.add header_cell
      end

      @schema
    end

    def parse_headers
      headers = []
      data_sheet.header_row.each_with_index do |header, column_index|
        next if header.blank?

        unless data_sheet.valid_header?(header)
          @schema.add HeaderCell.new(user_attribute: nil, column_index: column_index, present_in_sheet: true, content: header, is_supported_header: false)
          next
        end

        if data_sheet.generic_header?(header)
          present_in_sheet = true
          user_attribute = HeaderAlias.user_attribute_for_header(header)
        elsif data_sheet.custom_field_header?(header)
          # Ignore custom fields if company hasn't provisioned syncing of custom fields.
          present_in_sheet = data_sheet.consider_custom_fields? ? true : false
          user_attribute = company.custom_field_mappings.custom_field_mapping.find { |cfm| cfm.provider_key == header }.key
        end
        headers << HeaderCell.new(user_attribute: user_attribute.to_sym, column_index: column_index, present_in_sheet: present_in_sheet, content: header, is_supported_header: true)
      end
      headers
    end

    private

    def supported_attributes
      HeaderAlias::HEADER_ALIAS_MAP.map { |_key, attrs| attrs.fetch(:attribute_identifier) }
    end

    def data_sheet
      @data_sheet ||= AccountsSpreadsheetImport::DataSheet.new(data_sheet_file: data_sheet_file)
    end
  end

  class HeaderRowSchema
    #
    # Represents an array of HeaderCell object.
    #
    include ActiveModel::Model

    validate :validate_presence_of_required_columns
    validate :validate_absence_of_unsupported_columns
    validate :validate_absence_of_duplicate_columns

    attr_reader :header_cells

    attr_accessor :company

    def initialize(company)
      @company = company
      @header_cells = []
    end

    def add(header_cell)
      header_cells << header_cell
    end

    def user_attribute_is_a_column_in_user_table?(user_attribute)
      User.columns.map(&:name).map(&:to_sym).include? user_attribute.to_sym
    end

    def attributes_to_ignore
      @attributes_to_ignore ||= header_cells.reject(&:present_in_sheet).select(&:is_supported_header).map(&:user_attribute)
    end

    def attributes_to_upsert
      @attributes_to_upsert ||= header_cells.select(&:present_in_sheet).select(&:is_supported_header).map(&:user_attribute)
    end

    def attributes_to_upsert_directly_in_user_table
      @attributes_to_upsert_directly_in_user_table = header_cells
        .select(&:present_in_sheet)
        .select(&:is_supported_header)
        .select { |header| user_attribute_is_a_column_in_user_table?(header.user_attribute) }
        .map(&:user_attribute)
    end

    def header_cell_for_attribute(user_attribute)
      header_cells.find { |header| header.user_attribute == user_attribute.to_sym }
    end

    def attributes_required
      attributes = [:email]
      # attributes.delete(:email) if company.settings.allow_phone_authentication?
      attributes
    end

    private

    def validate_absence_of_unsupported_columns
      unsupported_columns = header_cells.select(&:present_in_sheet).reject(&:is_supported_header)
      return if unsupported_columns.blank?

      self.errors.add(:base, "Unsupported headers found: #{unsupported_columns.map(&:content).join(", ")}!")
    end

    def validate_absence_of_duplicate_columns
      header_cells_present_in_sheet = header_cells.select(&:present_in_sheet).select(&:is_supported_header)
      user_attributes_for_header_cells_present_in_sheet = header_cells_present_in_sheet.map(&:user_attribute)
      duplicate_header_cell = header_cells_present_in_sheet.reject do |header_cell|
        user_attributes_for_header_cells_present_in_sheet.rindex(header_cell.user_attribute) ==
          user_attributes_for_header_cells_present_in_sheet.index(header_cell.user_attribute)
      end
      return if duplicate_header_cell.blank?

      self.errors.add(:base, "Duplicate columns found: #{duplicate_header_cell.map(&:content).uniq.join(", ")}!")
    end

    def validate_presence_of_required_columns
      missing_required_attributes = attributes_required.select do |attribute|
        header_cell_for_attribute(attribute)&.present_in_sheet == false
      end
      return if missing_required_attributes.blank?

      missing_headers = missing_required_attributes.map { |attr| HeaderAlias.header_for_user_attribute(attr) }
      self.errors.add(:base, "Required columns are missing: #{missing_headers.map(&:humanize).join(", ")}!")
    end
  end

  class HeaderCell
    #
    # Represents a header cell.
    #
    include ActiveModel::Model

    attr_accessor :content, :user_attribute, :present_in_sheet, :column_index, :is_supported_header

    def initialize(attributes = {})
      super
    end
  end
end
