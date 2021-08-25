class AddIntervalFrequencyToRewards < ActiveRecord::Migration[4.2]
  def change
    add_column :rewards, :frequency, :integer
    add_column :rewards, :interval_id, :integer
  end
end
