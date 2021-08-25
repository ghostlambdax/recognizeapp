class RenameLastAccountsSpreadsheetImportProblematicRecordsDocumentInCompanies < ActiveRecord::Migration[5.0]
  def change
    rename_column :companies,
                  :last_accounts_spreadsheet_import_problematic_records_document_id,
                  :last_accounts_spreadsheet_import_results_document_id
  end
end
