class UpdateSyncGroupsInCompanySetting < ActiveRecord::Migration[4.2]
  include YammerClient
  # Before this migration, when a company chose which teams to sync, the whole payload for each team was stored, which limited how many teams could be synced. The max was around 60-70 when done this way.
  # Refactoring of microsoft_graph_sync_teams and yammer_sync_teams attribute on the CompanySettings model was done so that only id and name were stored, thus increasing the max number of teams that could be synced.  This migration accomdates the refactoring for past data.
  def change
    # data migration only, dont run on init

  end
end
