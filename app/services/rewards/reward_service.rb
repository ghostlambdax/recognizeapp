module Rewards
  class RewardService

    def self.template_rewards
      Company.find_by(domain: "recognizeapp.com").rewards.published
    end

    def self.find_template_reward(id)
      recognize = Company.find_by(domain: "recognizeapp.com")
      recognize.rewards.published.find_by(id: id)
    end

    def self.process_provider_redemption(redemption)

      provider = redemption.reward.provider_reward.get_client

      # each provider client should implement the Client.redeem method
      provider::Client.redeem(redemption)
    end

    # Providers created via this method also need to have a corresponding client
    # that uses the convention of the name
    # eg, "tango_card" => TangoCard::Client
    def self.create_reward_provider(name)
      Rewards::RewardProvider.where(name: name).first_or_create!(name: name)
    end

    def self.provider_rewards(catalog)
      Rewards::ProviderReward.active.by_currency(catalog.currency).includes(:rewards).order("name asc")
    end

    def self.sync_provider_rewards

      providers = Rewards::RewardProvider.where(active:true)

      providers.each do |provider|
        provider.get_client::Client.get_rewards.each { |reward| reward.create_or_update }
        provider.get_client::DiscontinuedRewardResolver.resolve_all
      end
    end
  end
end
