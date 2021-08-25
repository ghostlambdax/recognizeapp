# frozen_string_literal: true

module Rewards
  module ProviderSyncDeviation
    module ProviderReward
      class StatusChangeHandler < BaseHandler
        #
        # When a provider_reward is disabled, it requires handling of provider_reward_variants, relevant rewards (and
        # subsequently relevant reward_variants) as well as pending redemptions. Since we disable the
        # provider_reward_variants, which will trigger its handler for status change, we delegate handling of relevant
        # rewards (and subsequently relevant reward_variants) as well as pending redemptions to provider_reward_variants'
        # handlers
        #

        def object_klass
          Rewards::ProviderReward
        end

        def provider_reward
          object
        end

        def handle
          log "Handling status change to `disabled`!"
          disable_relevant_provider_reward_variants
        end

        def relevant_provider_reward_variants
          provider_reward.provider_reward_variants
        end

        def disable_relevant_provider_reward_variants
          log("There aren't any relevant provider reward variants to disable.") && return if relevant_provider_reward_variants.blank?

          log "Disabling #{relevant_provider_reward_variants.size} relevant provider reward variants..."
          relevant_provider_reward_variants.each do |provider_reward_variant|
            log "Disabling provider reward variant(id: #{provider_reward_variant.id})"
            provider_reward_variant.update!(status: "disabled")
          end
        end
      end
    end
  end
end
