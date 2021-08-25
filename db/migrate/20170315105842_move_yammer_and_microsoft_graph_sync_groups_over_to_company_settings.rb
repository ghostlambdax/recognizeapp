class MoveYammerAndMicrosoftGraphSyncGroupsOverToCompanySettings < ActiveRecord::Migration[4.2]
  def change
    # data migration only, dont run on init
    if Company.count > 0
      # If a company doesn't yet have an associated CompanySetting persisting in the db, create one.
      Company.all.each do |c|
        unless c.settings.persisted?
          c.create_settings!
        end
      end

      # Move yammer_sync_groups
      sql = "UPDATE company_settings INNER JOIN companies ON companies.id = company_settings.company_id SET company_settings.yammer_sync_groups = companies.yammer_sync_groups"
      ActiveRecord::Base.connection.execute(sql)

      # Move microsoft_graph_sync_groups
      sql = "UPDATE company_settings INNER JOIN companies ON companies.id = company_settings.company_id SET company_settings.microsoft_graph_sync_groups = companies.microsoft_graph_sync_groups"
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
