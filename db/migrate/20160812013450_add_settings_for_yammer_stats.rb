class AddSettingsForYammerStats < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :permit_yammer_stats, :boolean, default: false
    add_column :companies, :enable_yammer_stats, :boolean, default: false
  end
end
