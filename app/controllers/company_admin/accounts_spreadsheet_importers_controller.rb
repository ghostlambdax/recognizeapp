class CompanyAdmin::AccountsSpreadsheetImportersController < CompanyAdmin::BaseController

  def new
    # Three cases 1) no import is queued or in progress 2) import is queued 3) Import is in progress
    # If its in case 2 or 3, we’ll hide the form and inform that there is a queue import in progress.
    @queued_accounts_spreadsheet_importer = queued_accounts_spreadsheet_importer
    unless @queued_accounts_spreadsheet_importer.present?
      @accounts_spreadsheet_importer = AccountsSpreadsheetImport::ImportService.new()
    end
    @last_import_summary = @company.last_accounts_spreadsheet_import_summary
  end

  def show_last_import
    @last_import_summary = @company.last_accounts_spreadsheet_import_summary
  end

  def upload_data_sheet
    attrs = accounts_spreadsheet_importer_params
      .except(:file)
      .merge(action: :upload_data_sheet)
    @accounts_spreadsheet_importer = AccountsSpreadsheetImport::ImportService.new(attrs)
    @accounts_spreadsheet_importer.file = accounts_spreadsheet_importer_params[:file]
    @accounts_spreadsheet_importer.check_data_sheet_file_validity

    if @accounts_spreadsheet_importer.errors.blank?
      @company.last_accounts_spreadsheet_import_file = @accounts_spreadsheet_importer.file
      @company.save
      # Check to see if there are any validation errors thrown by Carrierwave.
      import_file_error = @company.errors[:last_accounts_spreadsheet_import_file]
      if import_file_error.present?
        # Add the carrierwave generated error on the company object to AccountsSpreadsheetImporter object.
        @accounts_spreadsheet_importer.errors.add(:file, import_file_error[0])
      end
    end

    if @accounts_spreadsheet_importer.errors.present?
      respond_with @accounts_spreadsheet_importer
    else
      render json: {
        status: 200,
        process_data_sheet_endpoint: process_data_sheet_company_admin_accounts_spreadsheet_importers_path
      }
    end
  end

  def process_data_sheet
    attrs = accounts_spreadsheet_importer_params
      .except(:file)
      .merge(action: :process_data_sheet)
    @job = Delayed::Job.enqueue AccountsSpreadsheetImport::ImportService.new(attrs), :queue => 'import', priority: -5 # higher than normal priority
  end

  private

  def accounts_spreadsheet_importer_params
    params[:accounts_spreadsheet_import_import_service] ?
      params
        .require(:accounts_spreadsheet_import_import_service)
        .permit(
          :file,
          :update_only,
          :remove_users
        ).tap{ |hash|
        hash[:importing_actor_signature] = current_user.actor_signature
        hash[:company_id] = @company.id
        hash[:requested_at] = Time.current
      }
      :
      params.permit
  end

  # Looks in DJ table to find a AccountsSpreadsheetImporter job belonging to the company.
  def queued_accounts_spreadsheet_importer
    dummy_accounts_spreadsheet_importer_obj = AccountsSpreadsheetImport::ImportService.new(company_id: @company.id)
    # DelayedDuplicatePreventionPlugin appends the `method_name` in `signature`.
    signature ="#{dummy_accounts_spreadsheet_importer_obj.signature}##{dummy_accounts_spreadsheet_importer_obj.method_name}"
    Delayed::Job.where(failed_at: nil).find_by_signature(signature)
  end
end
