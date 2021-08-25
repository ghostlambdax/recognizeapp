class AddImportDataForBulkRecognitions < ActiveRecord::Migration[5.0]
  def change
    add_column :recognitions, :bulk_imported_at, :datetime
    add_column :recognitions, :bulk_imported_by_id, :integer 
  end
end
