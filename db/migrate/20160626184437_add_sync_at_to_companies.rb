class AddSyncAtToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :last_synced_at, :datetime
  end
end
