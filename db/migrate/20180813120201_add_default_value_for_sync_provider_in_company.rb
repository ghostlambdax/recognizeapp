class AddDefaultValueForSyncProviderInCompany < ActiveRecord::Migration[5.0]
  def up
    new_column_default = 'microsoft_graph'
    Company.unscoped.where(sync_provider: nil).find_each do |company|
      default_provider = default_sync_provider(company) || new_column_default
      company.update_column(:sync_provider, default_provider)
    end

    change_column_default :companies, :sync_provider, new_column_default
  end

  # the data mutation is not reversible
  def down
    change_column_default :companies, :sync_provider, nil
  end

  private

  # moved from company.rb, as it is no longer needed there
  def default_sync_provider(company)
    Authentication
      .where(user_id: company.company_admins.map(&:id), provider: UserSync.authenticable_providers)
      .last.try(:provider)
  end
end
