class AddProviderSpecificSyncGroupsColumns < ActiveRecord::Migration[4.2]
  def change
    rename_column :companies, :sync_groups, :yammer_sync_groups
    add_column :companies, :microsoft_graph_sync_groups, :text
  end
end
