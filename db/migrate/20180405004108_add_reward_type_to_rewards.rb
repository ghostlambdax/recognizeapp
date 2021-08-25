class AddRewardTypeToRewards < ActiveRecord::Migration[4.2]
  def up
    add_column :rewards, :reward_type, :string
    add_column :provider_rewards, :reward_type, :string

    execute "ALTER TABLE provider_reward_variants CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    execute "ALTER TABLE provider_reward_variants MODIFY name VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    execute "ALTER TABLE provider_rewards MODIFY short_description text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    execute "ALTER TABLE provider_rewards MODIFY description text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    execute "ALTER TABLE provider_rewards MODIFY terms text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"

    if !Rails.env.test? && Recognize::Application.config.rCreds.has_key?("tangocard")
      # resync to update the reward type on the ProviderReward
      puts "Syncing rewards to grab reward_type"
      # Rewards::RewardService.sync_provider_rewards

      # Update all Rewards with the reward type as well
      puts "Ensuring rewards have reward type based on provider reward"
      Rewards::ProviderReward.all.each do |pr|
        Reward.where(provider_reward_id: pr.id).update_all(reward_type: pr.reward_type)
      end
    end
  end

  def down
    remove_column :rewards, :reward_type
    remove_column :provider_rewards, :reward_type
  end
end
