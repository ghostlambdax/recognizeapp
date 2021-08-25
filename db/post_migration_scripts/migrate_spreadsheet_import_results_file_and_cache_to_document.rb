# Note: The script in this file is to be run after running the migration at
# `db/migrate/20190917113251_add_metadata_to_attachments.rb`

class SpreadsheetImportResultsCompanyToDocumentMigrator
  def self.run(dry_run: true)
    ActiveRecord::Base.transaction do
      new(dry_run).migrate
    end
  end

  attr_reader :dry_run

  def initialize(dry_run)
    @dry_run = dry_run
  end

  def migrate
    Rails.logger.info "This is just a dry run and no data will be mutated!".upcase if dry_run

    Rails.logger.info "*" * 80 + "\nMigration of last spreadsheet import results file and cache data to document --  BEGIN\n" + "*" * 80
    handle_migration_of_last_accounts_spreadsheet_import_problematic_records_files_to_documents!
    Rails.logger.info "-" * 80 + "\n"
    handle_migration_of_import_results_from_cache_to_documents!
    Rails.logger.info "*" * 80 + "\nMigration of last spreadsheet import results file and cache data to document -- END\n" + "*" * 80

    # Be defensive
    raise ActiveRecord::Rollback, "Dry run in progress!" if dry_run
  end

  def handle_migration_of_last_accounts_spreadsheet_import_problematic_records_files_to_documents!
    Rails.logger.info "# Executing #{__method__}..."
    Company.where.not(last_accounts_spreadsheet_import_problematic_records_file: nil).each do |company|
      Rails.logger.info "\t# Running for #{company.domain}..."
      migrate_last_accounts_spreadsheet_import_problematic_records_file_to_document!(company)
    end
  end

  def handle_migration_of_import_results_from_cache_to_documents!
    Rails.logger.info "# Executing #{__method__}..."
    Company.where.not(last_accounts_spreadsheet_import_results_document_id: nil).each do |company|
      Rails.logger.info "\t# Running for #{company.domain}..."
      migrate_import_results_from_cache_to_document!(company)
      remove_import_results_from_cache(company)
    end
  end

  def migrate_last_accounts_spreadsheet_import_problematic_records_file_to_document!(company)
    Rails.logger.info "\t\tExecuting #{__method__}..."

    # For companies which have performed an import after the newer architecture was implemented(post PR#2447),
    # the `last_accounts_spreadsheet_import_problematic_records_file` has already been nil-ified.
    if company.last_accounts_spreadsheet_import_problematic_records_file.blank?
      Rails.logger.info "\t\tSkipping! Attribute `last_accounts_spreadsheet_import_problematic_records_file` doesn't need any consideration."
      return
    end

    return if dry_run

    import_results_from_cache = get_last_accounts_spreadsheet_import_cache(company)
    file_to_migrate = if company.last_accounts_spreadsheet_import_file.url.match(/^http/)
      File.open(Down.download(company.last_accounts_spreadsheet_import_file.url))
    else
      File.open(company.last_accounts_spreadsheet_import_file.path)
    end

    document = Document.create!(
      company_id: company.id,
      uploader_id: User.system_user.id,
      file: file_to_migrate,
      original_filename: "Accounts spreadsheet import results.xlsx",
      requester_id: get_requester_id_from_cache_entry(import_results_from_cache),
      requested_at: import_results_from_cache&.started_at,
      description: "Spreadsheet import results",
      )
    company.update_column(:last_accounts_spreadsheet_import_results_document_id, document.id)
  end

  def migrate_import_results_from_cache_to_document!(company)
    Rails.logger.info "\t\tExecuting #{__method__}..."
    return if dry_run

    import_results_from_cache = get_last_accounts_spreadsheet_import_cache(company)
    company.last_accounts_spreadsheet_import_results_document.update_column(:metadata, import_results_from_cache)
  end

  def remove_import_results_from_cache(company)
    Rails.logger.info "\t\tExecuting #{__method__}..."
    Rails.logger.info "\t\t\tRather than delete the cache, we wait for it to expire on its own"
    return if dry_run
    # Rails.cache.delete(company.last_accounts_spreadsheet_import_cache_key)
  end

  private

  def get_last_accounts_spreadsheet_import_cache(company)
    data = Rails.cache.fetch(last_accounts_spreadsheet_import_cache_key(company))
    return nil if data.blank?

    if data.importing_actor_signature.blank?
      # The Hashie object stored in the cache for historic spreadsheet importrs (earlier than May 16-ish, 2018) stored
      # importer_id instead of importing_actor_signature, and also didn't have the implementation of sftp sync.
      data.importing_actor_signature = User.find_by_id(data.importer_id)&.actor_signature
    end
    data
  end

  def get_requester_id_from_cache_entry(cache_entry)
    # Take into consideration that the relevant cache might have expired.
    return nil if cache_entry.blank?

    # If the importing actor is sftp import, the requester_id is kept nil.
    cache_entry.importing_actor.is_a?(User) ? cache_entry.importing_actor.id : nil
  end

  def last_accounts_spreadsheet_import_cache_key(company)
    "company-#{company.id}-last-accounts-spreadsheet-import"
  end
end

# SpreadsheetImportResultsCompanyToDocumentMigrator.run(dry_run: true)
