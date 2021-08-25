# frozen_string_literal: true

#
# Used to run validations on the data sheet file provided.
#
module AccountsSpreadsheetImport
  class DataSheetValidator
    include ActiveModel::Model
    attr_accessor :data_sheet_file

    def initialize(attributes = {})
      super
    end

    # Note: The ordering of the following validations, and the immediate return-ing are important.
    # For instance, data sheet file checks are delibarately done first to ensure the latter checks for data sheet(content)
    # don't thrown an error, since if there is problem with data sheet file itself, building a data sheet is erroneous.
    def validate
      if data_sheet_file.file.blank?
        errors.add(:file, 'must be present.')
        return
      end

      unless data_sheet_file.correct_extension?
        errors.add(:file,
                   I18n.t("errors.messages.extension_allowlist_error",
                          extension: data_sheet_file.extension.inspect,
                          allowed_types: data_sheet_file.expected_extensions.join(",")))
        return
      end

      if data_sheet.blank?
        errors.add(:file, "can not be blank.")
        return
      end

      unless data_sheet.schema.valid?
        data_sheet.schema.errors.full_messages.each do |message|
          errors.add(:file, "^#{message}")
        end
        return
      end

      unless data_sheet.account_record_rows?
        errors.add(:file, "doesn't have any account rows to process.")
      end
    end

    private

    def data_sheet
      @data_sheet ||= AccountsSpreadsheetImport::DataSheet.new(data_sheet_file: data_sheet_file)
    end
  end
end
