class RemoveSyncServiceAnniversaryDataAndSyncManagersFromCompany < ActiveRecord::Migration[4.2]
  def change
    settings = [
        :sync_managers,
        :sync_service_anniversary_data
    ]
    settings.each do |setting|
      remove_column :companies, setting
    end
  end
end
