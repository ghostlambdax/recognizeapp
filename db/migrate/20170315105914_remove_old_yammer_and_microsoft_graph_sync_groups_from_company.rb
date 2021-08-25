class RemoveOldYammerAndMicrosoftGraphSyncGroupsFromCompany < ActiveRecord::Migration[4.2]
  def change
    settings = [
        :yammer_sync_groups,
        :microsoft_graph_sync_groups
    ]
    settings.each do |setting|
      remove_column :companies, setting
    end
  end
end
