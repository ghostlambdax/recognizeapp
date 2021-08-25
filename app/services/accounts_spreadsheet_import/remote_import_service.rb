# frozen_string_literal: true

# This is meant to be run in background task
# See Api::V2::Endpoints::Users::Import
# or /users/import

require "down"

module AccountsSpreadsheetImport
  class RemoteImportService
    attr_reader :company, :url, :importer, :opts, :errors, :tempfile

    def self.import(company_id, url, opts = {})
      new(company_id, url, opts).import
    end

    def initialize(company_id, url, opts = {})
      @company = Company.find(company_id)
      @url = url
      @opts = default_opts.merge(opts)
      @importer = AccountsSpreadsheetImport::ImportService.new(@opts)
      @importer.url = url # need in the init so that url is always there for error messages that may occur prior to calling #import
      @importer.importing_actor_signature = AccountsSpreadsheetImport::RemoteImportService::SftpActor.new(company_id).actor_signature
      @importer.company_id = company_id
    end

    def default_opts
      # These are sensible defaults
      # TODO: let companies specify this via setting/company admin
      {update_only: false, remove_users: true, requested_at: Time.current}
    end

    def errors
      importer.errors
    end

    def import
      # Note: The `remote_<attachment_column_name>_url= `,  a dynamic method of Carrierwave, downloads file from the
      # passed `url`, and saves it when company is saved.
      importer.url = url
      company.remote_last_accounts_spreadsheet_import_file_url = importer.url

      begin
        company.save!
      rescue ActiveRecord::RecordInvalid => e
        importer.errors.add(:file, e.message)
      end

      if importer.errors.blank?
        importer.file = if company.last_accounts_spreadsheet_import_file.url.match(/^http/)
          # NOTE: Previously we would wrap the return value of Down.download (TempFile)
          #       in File.open
          #       However, we're seeing that Ruby is intermittently garbage collecting
          #       the tempfile because for some reason it thinks that its no longer used.
          #       So, we're going to stash the tempfile in an instance variable
          #       and cross our fingers that Ruby doesn't GC it.
          #       Here is a good discussiong and reproduction of the issue:
          #       https://www.hilman.io/blog/2016/01/tempfile/
          @tempfile = Down.download(company.last_accounts_spreadsheet_import_file.url)
          File.open(@tempfile)
        else
          File.open(company.last_accounts_spreadsheet_import_file.path)
        end

        # Additional paranoid debug logging
        begin
          Rails.logger.debug "RemoteImportService#import - Size: #{importer.file.inspect}"
          Rails.logger.debug "RemoteImportService#import - meta: #{importer.file.size}  - #{importer.file.eof?}"
        rescue => e
          Rails.logger.debug "Caught exception in debug logging - #{e.message}"
        end

        importer.check_data_sheet_file_validity
      end

      if importer.errors.blank?
        company.save

        # Check to see if there are any validation errors thrown by Carrierwave.
        import_file_error = company.errors[:last_accounts_spreadsheet_import_file]

        if import_file_error.present?
          # Add the carrierwave generated error on the company object to AccountsSpreadsheetImporter object.
          importer.errors.add(:file, import_file_error)
          self.send_error_report!

        else
          importer.perform
        end

      else
        self.send_error_report!
      end
    rescue StandardError => e
      ::Recognizebot.say(text: "<!subteam^SQECBCGAW> RemoteImportService#import failed for Company(#{company.domain}) - #{e.message}", channel: "#system-notifications")
      Rails.logger.debug "Caught exception importing file: #{url}"
      Rails.logger.debug "Exception: #{e.message}"

      Rails.logger.debug "Data Sheet File: #{data_sheet_file}" rescue nil
      Rails.logger.debug "Data Sheet File path: #{data_sheet_file.path}" rescue nil
      Rails.logger.debug "Data Sheet File ext: #{data_sheet_file.extension}" rescue nil
      Rails.logger.debug "csv's in tmp folder: #{Dir["/tmp/**/*.csv"].join(", ")}" rescue nil
      raise e
    end

    def send_error_report!
      AccountsSpreadsheetImporterNotifier
        .spreadsheet_import_report(company.sync_report_notifieds, importer)
        .deliver_now
    end

    def valid_to_process?
      if !company.sync_enabled?
        importer.errors.add(:company, "Spreadsheet received but user sync is not enabled. Please visit the Company Admin > Settings to turn this on.")
      elsif company.sync_provider.try(:to_sym) != :sftp
        importer.errors.add(:company, "Sync provider has not been specified as sFTP. Import will not be scheduled.")
      end
      importer.errors.blank?
    end

    class BaseActor
      include ActorConcern

      attr_reader :company_id
      def initialize(company_id)
        @company_id = company_id
      end

      def actor_signature_id
        company_id
      end

      def label
        raise "must be implemented by subclasses"
      end
    end

    class SftpActor < BaseActor
      def label
        "sFTP import"
      end
    end
  end
end
