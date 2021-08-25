# frozen_string_literal: true

#
# Represents the uploaded data sheet file.
# This class is different from `DataSheet` class such that `DataSheetFile` deals with basic file related
# activities, where as `DataSheet` deals with any activities that needs peeking inside the sheet content.
#
module AccountsSpreadsheetImport
  class DataSheetFile
    include ActiveModel::Model
    attr_accessor :file, :company

    def initialize(attributes = {})
      super
    end

    def path
      file.respond_to?(:url) && file.url.match(/^http/) ? file.url : file.path
      # last_accounts_spreadsheet_import_file = company.last_accounts_spreadsheet_import_file
      # if last_accounts_spreadsheet_import_file.url.present? && last_accounts_spreadsheet_import_file.url.match(/^http/)
      #   file.url # File is stored in S3 in production
      # else
      #   file.path
      # end
    end

    def extension
      # See AccountsSpreadsheetImport::ImportService.new#file for comments on how the `file` attribute can be objects
      # of different classes.
      io_file = file.class.ancestors.include?(CarrierWave::Uploader::Base) ? file.file : file
      path = io_file.respond_to?(:path) ? io_file.path : io_file.original_filename.downcase
      File.extname(path).delete(".")
    end

    def correct_extension?
      expected_extensions.include? extension
    end

    def expected_extensions
      AccountsSpreadsheetUploader.new.extension_allowlist
    end
  end
end
