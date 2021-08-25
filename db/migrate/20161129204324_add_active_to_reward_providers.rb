class AddActiveToRewardProviders < ActiveRecord::Migration[4.2]
  def change
    add_column :reward_providers, :active, :boolean, default: false

    Rewards::RewardProvider.reset_column_information

    # create the first reward provider
     tango = Rewards::RewardService.create_reward_provider('tango_card')
     tango.activate!

  end
end
