module TangoCard
  class DiscontinuedRewardResolver
    class << self
      attr_reader :brands_from_provider

      def resolve_all
        @brands_from_provider = Client.get_rewards
        discontinued_provider_rewards.each { |provider_reward| self.resolve(provider_reward) }
        discontinued_provider_reward_variants.each { |provider_reward_variant| self.resolve(provider_reward_variant) }
      end

      def resolve(resolvable)
        new(resolvable).resolve
      end

      # A brand's `brandKey` maps to the relevant provider_reward's `provider_key`.
      def discontinued_provider_rewards
        brand_key_of_all_brands = brands_from_provider.map(&:brand_key).flatten
        provider_keys_of_all_provider_rewards = Rewards::ProviderReward.pluck(:provider_key).uniq

        missing_provider_keys = provider_keys_of_all_provider_rewards - brand_key_of_all_brands
        # Filter out already disabled records.
        Rewards::ProviderReward.where(status: "active", provider_key: missing_provider_keys).to_a
      end

      # A brand's item's `utid` maps to the relevant provider_reward_variant's `provider_key`.
      def discontinued_provider_reward_variants
        utis_of_all_brand_items = brands_from_provider.map { |brand| brand.rewards.map(&:utid).uniq }.flatten
        provider_keys_of_all_provider_reward_variants = Rewards::ProviderRewardVariant.pluck(:provider_key).uniq

        missing_provider_keys = provider_keys_of_all_provider_reward_variants - utis_of_all_brand_items
        # Filter out already disabled records.
        Rewards::ProviderRewardVariant.where(status: "active", provider_key: missing_provider_keys).to_a
      end
    end

    attr_reader :discontinued_object

    def initialize(discontinued_object)
      @discontinued_object = discontinued_object
    end

    def resolve
      handler.delay(queue: 'priority_caching').handle(discontinued_object.id)
    end

    def handler
      "Rewards::ProviderSyncDeviation::#{discontinued_object.class.name.demodulize}::DiscontinuanceHandler".constantize
    end
  end
end
