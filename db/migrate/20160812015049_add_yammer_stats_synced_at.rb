class AddYammerStatsSyncedAt < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :yammer_stats_synced_at, :datetime
  end
end
