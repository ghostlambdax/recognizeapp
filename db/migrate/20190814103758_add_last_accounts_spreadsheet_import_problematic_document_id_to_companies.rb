class AddLastAccountsSpreadsheetImportProblematicDocumentIdToCompanies < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :last_accounts_spreadsheet_import_problematic_records_document_id, :integer
  end
end
