class AddSyncFiltersToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column(:company_settings, :sync_filters, :text)
  end
end
