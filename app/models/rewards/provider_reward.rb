module Rewards
  class ProviderReward < ApplicationRecord

    belongs_to :reward_provider, optional: true
    has_many :provider_reward_variants
    has_many :rewards

    scope :active, ->{ where(status: 'active')}
    scope :domestic, ->{ joins(:provider_reward_variants).where(provider_reward_variants: {currency_code: 'USD'}).distinct }
    scope :international, ->{ joins(:provider_reward_variants).where.not(provider_reward_variants: {currency_code: 'USD'}).distinct }
    scope :by_currency, ->(currency_code){ joins(:provider_reward_variants).where(provider_reward_variants: {currency_code: currency_code}).distinct }

    after_commit :handle_status_change_to_disabled, if: :status_changed_to_disabled?

    def discrete_values
      if self.variable_provider_reward?
        raise "This should not be called for variable provider rewards"
      end

      @discrete_values ||= begin
        self.provider_reward_variants.active.map do |prv|
          prv.face_value
        end
      end

    end

    def get_client
      self.reward_provider.get_client
    end

    def min_value
      if self.variable_provider_reward?
        self.provider_reward_variants.active.first.min_value
      else
        raise "Not implemented yet"
      end
    end

    def max_value
      if self.variable_provider_reward?
        self.provider_reward_variants.active.first.max_value
      else
        raise "Not implemented yet"
      end
    end

    # some provider rewards don't accept static currency amounts where
    # a range can be provided, is this one of those rewards
    def variable_provider_reward?
      self.provider_reward_variants.active.find { |variant| variant.value_type == 'VARIABLE_VALUE' }.present?
    end

    def active?
      self.status == 'active'
    end

    private

    def handle_status_change_to_disabled
      Rewards::ProviderSyncDeviation::ProviderReward::StatusChangeHandler.delay(queue: 'priority_caching').handle(self.id)
    end

    def status_changed_to_disabled?
      self.status_previously_changed? && self.status == "disabled"
    end
  end
end
