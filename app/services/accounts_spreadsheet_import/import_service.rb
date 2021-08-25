# frozen_string_literal: true

require 'roo'

module AccountsSpreadsheetImport
  class ImportService < ProgressJob::Base
    include AccountsSpreadsheetImport::BackgroundJobHelper
    #
    # This job's execution requisites(in development env):
    #
    # "Delayed::Worker.delay_jobs"    "bin/delayed_job start"     "Remarks"               ProgressBar
    # ---------------------------------------------------------------------------------------------------------------
    #   false                            false               Import/Email work             Doesn't work
    #   true                             false               Queued but not processed      Job is polled. But no progress shown.
    #   false                            true                Import/Email work             Doesn't work
    #   true                             true                Import/Email work             Works
    #

    #
    # Story:
    # -a datasheet file is uploaded
    # -the file is attached to the company
    # -upon successful attachment, a delayed job process is fired for import
    # -progress job keeps track of the progress in the frontend
    # -upon completion
    #   - if the job had records that failed or that were saved but require attention,
    #       - create datasheet with problematic records, and attach to the company
    #   - an email is sent to the importing actor
    #   - redirect to last_import_status page
    #   -last_import_status page will have status for failed and successful record count, and the failed records file
    #

    #
    # Types of user account records after processing the spreadsheet.
    #   - processed records
    #   - problematic records
    #     - accounts saved but need attention
    #       - optional fields could not be attached to the user account
    #     - failed to save the user
    #

    include ActiveModel::Model

    # Note:
    #  - update_only: 'dont add users, update attributes of found users only. Default: false.'
    #  - remove_users: 'Remove users not present in csv.'
    attr_accessor :company_id, :file, :importing_actor_signature, :update_only, :remove_users, :action, :url, :requested_at
    attr_reader :errors

    # company and importing_actor are set by controller and
    # super assigns to instance vars
    def initialize(attributes = {})
      super
      @errors = ActiveModel::Errors.new(self)
      @account_records = []
    end

    def file
      #
      # The attribute `action` can be either :upload_data_sheet or :process_data_sheet.
      # The spreadsheet import, from the front end, happens in two sequential steps. First, during :upload_data_sheet
      # action, it is attempted to attach the datasheet file to the company object(subject to validation). And, following
      # that, during :process_data_sheet, the file is fetched from the company object itself, and actual import process
      # happens.
      #
      # If the file to be processed is already attached to company object, :upload_data_sheet action is not required,
      # for example, as in sftp import.
      #
      # If action is :process_data_sheet, file is_a `CarrierWave::Uploader::Base` object.
      # If action is :upload_data_sheet,
      #     if sftp import, file is_a `File` object.
      #     if browser import, file is_a `ActionDispatch::Http::UploadedFile` object.
      #
      action == :process_data_sheet ? company.last_accounts_spreadsheet_import_file : @file
    end

    def data_sheet_file
      @data_sheet_file ||= AccountsSpreadsheetImport::DataSheetFile.new(file: file, company: company)
    end

    def data_sheet
      @data_sheet ||= AccountsSpreadsheetImport::DataSheet.new(data_sheet_file: data_sheet_file)
    end

    def notifieds
      # The `importing_actor` can be either a User object or a plain ruby class; it is a User object when import is done
      # via browser, and it is a plain ruby class, when import is done via sftp import.
      @notifieds ||= importing_actor_is_user? ? [importing_actor] : company.sync_report_notifieds
    end

    def importing_actor_is_user?
      importing_actor.is_a?(User)
    end

    def importing_actor_is_sftp_import?
      !importing_actor_is_user?
    end

    def user_that_adds_new_users
      notifieds.first
    end

    def importing_actor
      @actor = ActorConcern.actor_from_signature(importing_actor_signature)
    end

    def company
      @company ||= Company.find(company_id)
    end

    def perform
      @started_at = Time.current
      total_records_count = data_sheet.total_record_rows

      # `additional_progress_estimation` is a metric that estimates weight of processes that happen after processing
      # all account rows like create_import_results_document, notify_completion and like-wise.
      # Assume 30% of additional weight of processes is required other than processing the rows.
      additional_progress_estimation = total_records_count * 30 / 100
      update_progress_max(total_records_count + additional_progress_estimation)

      update_stage("Importing...")

      from_index = data_sheet.header_row_index + 1
      to_index = data_sheet.last_row_index

      (from_index..to_index).each do |index|
        update_progress(step: 1) # Inside the loop, as each row is processed step up the progress by 1.

        row = data_sheet.row(index)
        Rails.logger.debug "AccountsSpreadsheetImport#perform(#{company.domain})[#{index}/#{to_index}] - #{row}"
        account_record = AccountsSpreadsheetImport::AccountRecordBuilder.build(data_sheet: data_sheet, row: row)
        @account_records << account_record

        begin
          if account_record.skip_processing?
            Rails.logger.debug "AccountsSpreadsheetImport#perform(#{company.domain}) - skipping account record:\n #{account_record.inspect}"
            next
          end

          user = account_record.find_or_create_user(
            send_invitation: send_invitation,
            update_only: update_only,
            user_that_adds_new_users: user_that_adds_new_users
          )
          next if user.blank?

          account_record.process_attributes
        rescue => e
          account_record.errors.add(:base, e.message)
          ExceptionNotifier.notify_exception(e, data: {account_record: account_record.inspect, data_sheet_schema: data_sheet.schema})
        end
      end

      Rails.logger.debug "AccountsSpreadsheetImport#perform(#{company.domain}) - processing managers"
      process_managers

      # FIXME: If additional methods are added outside the loop, adjust `number_of_methods_called` accordingly.
      number_of_methods_called = 5
      additional_progress_estimation_cutoffs = additional_progress_estimation / number_of_methods_called

      Rails.logger.debug "AccountsSpreadsheetImport#perform(#{company.domain}) - deleting users"
      delete_users
      update_progress(step: additional_progress_estimation_cutoffs)

      Rails.logger.debug "AccountsSpreadsheetImport#perform(#{company.domain}) - refreshing cached users"
      refresh_cached_users
      update_progress(step: additional_progress_estimation_cutoffs)

      Rails.logger.debug "AccountsSpreadsheetImport#perform(#{company.domain}) - creating import results data sheet"
      create_import_results_document
      update_progress(step: additional_progress_estimation_cutoffs)

      Rails.logger.debug "AccountsSpreadsheetImport#perform(#{company.domain}) - notifying completion"
      notify_completion
      update_progress(step: additional_progress_estimation_cutoffs)

      update_stage("Imported!")
    end

    # Assigning of managers is done after all the rows have been traversed, and relevant users have been upserted.
    # Had it been done while upserting the user while looping over the rows, there might be a condition where a manager
    # comes later than the users she manages, resulting in manager not found case.
    def process_managers
      return unless data_sheet.schema.header_cell_for_attribute(:manager_email).present_in_sheet

      @account_records.each &:process_manager!

      Rails.logger.debug "AccountsSpreadsheetImport#perform(#{company.domain}) - processed managers, about to sync roles"
      ManagerRoleSyncer.delay(queue: 'priority_caching').sync!(company.id)
      Rails.logger.debug "AccountsSpreadsheetImport#perform(#{company.domain}) - sync'd manager roles"
    end

    def create_import_results_document
      import_results_temp_file = AccountsSpreadsheetImport::ImportResultsSheet.new(data_sheet, @account_records, import_summary).create

      if importing_actor_is_sftp_import?
        description = "sFTP Import results"
        rqstr = User.system_user
      else
        description = "Spreadsheet import results"
        rqstr = importing_actor
      end

      import_results_file_document = Document.create!(
        file: import_results_temp_file,
        company_id: company.id,
        uploader_id: User.system_user.id,
        original_filename: "Accounts spreadsheet import results.xlsx",
        requester_id: rqstr.id,
        requested_at: self.requested_at || Time.current,
        description: description,
        metadata: import_summary
      )

      company.update_column(:last_accounts_spreadsheet_import_results_document_id, import_results_file_document.id)

      import_results_temp_file&.close
      import_results_temp_file&.unlink
    end

    def refresh_cached_users
      company.refresh_cached_users!
    end

    def notify_completion
      AccountsSpreadsheetImporterNotifier.process_completion_email(notifieds, import_summary).deliver_now
    end

    def import_summary
      @import_summary ||= begin
        Hashie::Mash.new(
          started_at: @started_at,
          completed_at: Time.current,
          importing_actor_signature: importing_actor_signature,
          total_records_count: data_sheet.total_record_rows,
          successful_records_count: data_sheet.total_record_rows - problematic_records.size,
          failed_records_count: problematic_records.select { |record| record.errors.present? }.size,
          saved_but_require_attention_records_count: problematic_records.select { |record| record.warnings.present? }.size
        )
      end
    end

    def problematic_records
      @account_records.select { |account_record| account_record.errors.present? || account_record.warnings.present? }
    end

    # Remove users not present in datasheet.
    def delete_users
      return unless @remove_users

      users_to_delete = users_not_found
      users_to_delete = users_to_delete.reject(&:company_admin?)
      users_to_delete = users_to_delete.reject { |u| u.id == importing_actor.id } if importing_actor.respond_to?(:id)
      users_to_delete.each(&:destroy)
    end

    def check_data_sheet_file_validity
      data_sheet_validator = AccountsSpreadsheetImport::DataSheetValidator.new(data_sheet_file: data_sheet_file)
      data_sheet_validator.validate
      return unless data_sheet_validator.errors

      data_sheet_validator.errors.each do |_attribute, error|
        errors.add(:file, error)
      end
    rescue StandardError => e
      errors.add(:file, "^Sorry, something went wrong. Please ensure the data sheet is valid, or contact support.")
      Rails.logger.debug "ImportService#check_data_sheet_file_validity - Data Sheet File: #{data_sheet_file}" rescue nil
      Rails.logger.debug "ImportService#check_data_sheet_file_validity - Data Sheet File path: #{data_sheet_file.path}" rescue nil
      Rails.logger.debug "ImportService#check_data_sheet_file_validity - Data Sheet File ext: #{data_sheet_file.extension}" rescue nil
      Rails.logger.debug "ImportService#check_data_sheet_file_validity - csv's in tmp folder: #{Dir["/tmp/**/*.csv"].join(", ")}" rescue nil

      ExceptionNotifier.notify_exception(e, data: {message: "Error encountered while trying to resolve the headers. - #{e.message}", headers: data_sheet.schema.header_cells})
    end

    private

    def users_not_found
      successfully_processed_users = @account_records.select { |account_record| account_record.user.present? }.map(&:user)
      company.users.where.not(id: successfully_processed_users.map(&:id) )
    end

    # Never send invitations
    # Force this to always be false
    def send_invitation
      false
    end
  end
end
