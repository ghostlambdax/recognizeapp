class AddIntervalToCampaigns < ActiveRecord::Migration[4.2]
  def change
    add_column :campaigns, :interval_id, :integer
  end
end
