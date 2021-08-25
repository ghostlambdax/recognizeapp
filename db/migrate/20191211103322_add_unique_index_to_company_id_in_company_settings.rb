class AddUniqueIndexToCompanyIdInCompanySettings < ActiveRecord::Migration[5.0]
  def change
    remove_duplicate_company_settings
    add_index :company_settings, :company_id, unique: true

  # this will be raised if duplicates still exist when adding index
  rescue ActiveRecord::RecordNotUnique => e
    log_error(e)
  end

  private

  def remove_duplicate_company_settings
    # this query retrieves all records with non unique company_ids
    # as well the first entries among records with duplicated company_ids
    #   (preserving the existing settings associations for such companies)
    # ref: https://stackoverflow.com/a/49698214
    valid_ids = CompanySetting.group(:company_id).pluck('MIN(id)')

    CompanySetting.where.not(id: valid_ids).delete_all
  end

  def log_error(e)
    Rails.logger.error('Caught Exception in Migration: AddUniqueIndexToCompanyIdInCompanySettings:')
    Rails.logger.error(e.message)
    puts e.message
  end
end
