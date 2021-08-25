# frozen_string_literal: true

module AccountsSpreadsheetImport
  class AccountRecordBuilder
    include ActiveModel::Model

    attr_accessor :data_sheet, :row, :suffix
    attr_reader :account_record

    delegate :company, to: :data_sheet

    def self.build(attrs = {})
      new(attrs).account_record
    end

    def initialize(attrs = {})
      super
      # self.suffix = Rails.env.production? ? "" : ".not.real.tld"
      self.suffix = ''
    end

    def account_record
      self.row = row.map(&:to_s)

      employee_id = cell_content_for(:employee_id)&.strip&.downcase&.concat(suffix)
      email = cell_content_for(:email)&.strip&.downcase&.concat(suffix)
      first_name = cell_content_for(:first_name)&.strip
      last_name = cell_content_for(:last_name)&.strip
      job_title = cell_content_for(:job_title)&.strip
      phone = begin
        content = cell_content_for(:phone)&.strip
        content = (Twilio::PhoneNumber.format(content) || content) if content.present?
        content
      end
      team_names = cell_content_for(:team_names)&.split(data_sheet.team_delimiter)&.map(&:strip)
      role_names = cell_content_for(:role_names)&.split(data_sheet.role_delimiter)&.map(&:strip)
      start_date = cell_content_for(:start_date)&.strip
      birthday = cell_content_for(:birthday)&.strip
      manager_email = cell_content_for(:manager_email)&.strip&.concat(suffix)
      display_name = cell_content_for(:display_name)
      country = cell_content_for(:country)
      department = cell_content_for(:department)
      locale = cell_content_for(:locale)

      user_attributes = {
        company: company,
        employee_id: employee_id,
        email: email,
        first_name: first_name,
        last_name: last_name,
        job_title: job_title,
        phone: phone,
        team_names: team_names,
        role_names: role_names,
        start_date: start_date,
        birthday: birthday,
        manager_email: manager_email,
        display_name: display_name,
        country: country,
        department: department,
        locale: locale
      }
      user_attributes.merge!(custom_fields_attributes) if data_sheet.consider_custom_fields?

      AccountsSpreadsheetImport::AccountRecord.new(data_sheet.schema, user_attributes)
    end

    private

    def cell_content_for(attribute)
      return nil unless data_sheet.schema.header_cell_for_attribute(attribute).present_in_sheet

      attribute_column_index = data_sheet.schema.header_cell_for_attribute(attribute).column_index
      row[attribute_column_index].presence
    end

    def custom_fields_attributes
      return {} unless data_sheet.consider_custom_fields?

      attributes = {}
      company.custom_field_mappings.each do |mapping|
        custom_field_attribute_key = mapping.key.to_sym
        # BEGIN - Only track those custom_field attributes that have a corresponding column header in datasheet.
        if data_sheet.schema.header_cell_for_attribute(custom_field_attribute_key)&.present_in_sheet
          attributes[custom_field_attribute_key] = cell_content_for(custom_field_attribute_key)
        end
        # END - Only track those custom_field attributes that have a corresponding column header in datasheet.
      end
      attributes
    end
  end
end
