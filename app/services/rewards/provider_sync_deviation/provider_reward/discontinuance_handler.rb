# frozen_string_literal: true

module Rewards
  module ProviderSyncDeviation
    module ProviderReward
      class DiscontinuanceHandler < BaseDiscontinuanceHandler
        #
        # When a provider_reward is discontinued, we simply disable it, which will trigger a handler to take care of
        # disabling its provider_reward_variants, and relevant reward_variants and rewards as needed.
        #

        def object_klass
          Rewards::ProviderReward
        end

        class NotificationDraper < BaseDiscontinuanceHandler::NotificationDraper
          def actions_taken_on_object
            [
              "*Action taken*: Disabled!",
              "*Note*: A separate handler will take care of disabling provider_reward_variants, rewards and reward_variants if necessary."
            ]
          end

          def object_attributes_to_report
            %w[id name]
          end
        end
      end
    end
  end
end
