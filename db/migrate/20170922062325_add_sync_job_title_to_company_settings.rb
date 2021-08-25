class AddSyncJobTitleToCompanySettings < ActiveRecord::Migration[4.2]
  def change
    add_column :company_settings, :sync_job_title, :boolean, default: true
  end
end
