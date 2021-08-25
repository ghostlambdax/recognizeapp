module TangoCard
  class Brand
    attr_reader :brand_key, :brand_name, :disclaimer, :description, :short_description,
                :terms, :image_urls, :status, :rewards

    def initialize(params)
      @brand_key = params['brandKey']
      @brand_name = params['brandName']
      @disclaimer = params['disclaimer']
      @description = params['description']
      @short_description = params['shortDescription']
      @terms = params['terms']
      @image_urls = params['imageUrls']
      @status = params['status']
      @rewards = []
      params['items'].each do |reward|
        @rewards << Reward.new(reward)
      end
    end

    def create_or_update
      provider_reward = Rewards::ProviderReward.where(provider_key: self.brand_key).first
      if provider_reward.nil?
        provider_reward = Rewards::ProviderReward.new
      end

      provider_reward.reward_provider = Rewards::RewardProvider.find_by_name(:tango_card)
      provider_reward.provider_key = self.brand_key
      provider_reward.name = self.brand_name
      provider_reward.disclaimer = self.disclaimer
      provider_reward.description = self.description
      provider_reward.short_description = self.short_description
      provider_reward.terms = self.terms
      provider_reward.image_url = self.image_urls['300w-326ppi']
      provider_reward.status = self.status
      # kinda weird huh, Tango puts the reward_type on each variant
      # don't know if you could ever have a donation and a gift card
      # in one brand
      provider_reward.reward_type = self.rewards[0].reward_type
      provider_reward.save!
      self.rewards.each do |reward|
        reward.create_or_update(provider_reward)
      end

    end

    def international?
      self.rewards.any?{|reward| reward.currency_code != "USD" }
    end
  end
end
