class AddSyncFrequencyToCompanySetting < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :sync_frequency, :integer, default: CompanySetting.sync_frequencies[:weekly]
  end
end
