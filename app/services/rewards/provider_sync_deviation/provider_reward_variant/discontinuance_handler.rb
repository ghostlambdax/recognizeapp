# frozen_string_literal: true

module Rewards
  module ProviderSyncDeviation
    module ProviderRewardVariant
      class DiscontinuanceHandler < BaseDiscontinuanceHandler
        #
        # When a provider_reward_variant is discontinued, we simply disable it, which will trigger a handler to take
        # care of disabling its provider_reward_variants, and relevant reward_variants and rewards as needed.
        #

        def object_klass
          Rewards::ProviderRewardVariant
        end

        class NotificationDraper < BaseDiscontinuanceHandler::NotificationDraper
          def actions_taken_on_object
            [
              "*Action taken*: Disabled!",
              "*Note*: A separate handler will take care of disabling rewards and reward_variants if necessary."
            ]
          end

          def object_attributes_to_report
            %w[id name face_value value_type]
          end
        end
      end
    end
  end
end
