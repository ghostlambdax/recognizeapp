class UserCompanySettings < ActiveRecord::Migration[4.2]
  def change
    add_column(:companies, :sync_enabled, :boolean, default: false, nil: false)
    add_column(:companies, :sync_groups, :text)
    add_column(:users, :synced_at, :timestamp)
  end
end
