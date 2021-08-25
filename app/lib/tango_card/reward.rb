module TangoCard
  class Reward
    attr_reader :utid, :reward_name, :currency_code, :status, :value_type,
                :reward_type, :face_value, :countries, :min_value, :max_value

    def initialize(params)
      @utid = params['utid']
      @reward_name = params['rewardName']
      @currency_code = params['currencyCode']
      @status = params['status']
      @value_type = params['valueType']
      @reward_type = params['rewardType']
      @face_value = params['faceValue']
      @countries = params['countries']
      @min_value = params['minValue']
      @max_value = params['maxValue']
    end

    def create_or_update(provider_reward)
      provider_reward_variant = Rewards::ProviderRewardVariant.where(provider_key: self.utid).first
      if provider_reward_variant.nil?
        provider_reward_variant = Rewards::ProviderRewardVariant.new
      end

      provider_reward_variant.provider_reward = provider_reward
      provider_reward_variant.provider_key = self.utid
      provider_reward_variant.name = self.reward_name
      provider_reward_variant.currency_code = self.currency_code
      provider_reward_variant.status = self.status
      provider_reward_variant.value_type = self.value_type
      provider_reward_variant.reward_type = self.reward_type
      provider_reward_variant.face_value = self.face_value
      provider_reward_variant.min_value = self.min_value
      provider_reward_variant.max_value = self.max_value
      provider_reward_variant.countries = self.countries.join(',')
      provider_reward.reward_type = self.reward_type
      provider_reward_variant.save!
    end

  end
end
