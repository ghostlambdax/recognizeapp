class AddMetadataToAttachments < ActiveRecord::Migration[5.0]
  def change
    add_column :attachments, :metadata, :text

    # Note: This migration is to be followed up by script at
    # `db/post_migration_scripts/migrate_spreadsheet_import_results_file_and_cache_to_document.rb`
  end
end
