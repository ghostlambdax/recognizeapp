class AddProviderRewardtoReward < ActiveRecord::Migration[4.2]
  def change
    add_column :rewards, :provider_reward_id, :integer
  end
end
