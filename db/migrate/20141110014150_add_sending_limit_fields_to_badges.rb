class AddSendingLimitFieldsToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :sending_frequency, :integer
    add_column :badges, :sending_interval_id, :integer
  end
end
