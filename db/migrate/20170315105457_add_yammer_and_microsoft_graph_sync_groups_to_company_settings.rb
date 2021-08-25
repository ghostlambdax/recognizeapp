class AddYammerAndMicrosoftGraphSyncGroupsToCompanySettings < ActiveRecord::Migration[4.2]
  def change
    add_column(:company_settings, :yammer_sync_groups, :text)
    add_column(:company_settings, :microsoft_graph_sync_groups, :text)
  end
end
