class AddSyncProviderToCompany < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :sync_provider, :string
  end
end
