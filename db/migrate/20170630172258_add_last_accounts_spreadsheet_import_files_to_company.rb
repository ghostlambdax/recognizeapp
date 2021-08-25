class AddLastAccountsSpreadsheetImportFilesToCompany < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :last_accounts_spreadsheet_import_file, :string
    add_column :companies, :last_accounts_spreadsheet_import_problematic_records_file, :string
  end
end
