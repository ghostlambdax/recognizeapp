# frozen_string_literal: true

module Rewards
  module ProviderSyncDeviation
    module ProviderRewardVariant
      class StatusChangeHandler < BaseHandler
        #
        #  When a provider_reward_variant is disabled, the following is taken into account.
        #  All reward_variants that belong to the provider_reward_variant are disabled.
        #  For all relevant active rewards
        #    - If the reward has other reward_variants that are active, the reward stays active
        #    - If there are no more reward_variants that are active, the reward is disabled
        #  If a reward_variant that was disabled in steps above is tied to a pending redemption, that is a \@support ping
        #  to slack case
        #

        def object_klass
          Rewards::ProviderRewardVariant
        end

        def provider_reward_variant
          object
        end

        def handle
          log "Handling status change to `disabled`!"
          disable_relevant_reward_variants
          disable_relevant_rewards
          admin_notifier.notify
        end

        def relevant_reward_variants
          @relevant_reward_variants ||= begin
            Rewards::RewardVariant.where(provider_reward_variant_id: provider_reward_variant.id, is_enabled: true)
          end
        end

        def disable_relevant_reward_variants
          log("There aren't any relevant reward variants to disable.") && return if relevant_reward_variants.blank?

          log "Disabling #{relevant_reward_variants.size} relevant reward variants..."
          relevant_reward_variants.each do |reward_variant|
            log "Disabling reward variant(id: #{reward_variant.id})"
            reward_variant.update_column(:is_enabled, false)
          end
        end

        def rewards_to_disable
          @rewards_to_disable ||= relevant_rewards.reject { |reward| reward_has_active_reward_variants?(reward) }
        end

        def disable_relevant_rewards
          log("There aren't any relevant rewards to disable.") && return if rewards_to_disable.blank?

          log "Disabling #{rewards_to_disable.size} relevant rewards..."
          rewards_to_disable.each do |reward|
            log "Disabling reward(id: #{reward.id})"
            reward.update!(enabled: false)
          end
        end

        def reward_has_active_reward_variants?(reward)
          reward.variants.enabled.present?
        end

        def relevant_rewards
          @relevant_rewards ||= Reward.enabled.where(id: relevant_reward_variants.map(&:reward_id).uniq)
        end

        def pending_redemptions
          Redemption.unapproved.includes(:reward_variant)
            .where(reward_variants: {provider_reward_variant_id: provider_reward_variant.id})
        end

        class NotificationDraper < SlackNotificationDraper
          def subject
            "A provider reward variant has been disabled!"
          end

          def provider_reward_variant_info
            provider_reward_variant.attributes.slice("id", "name", "face_value", "value_type").map do |key, value|
              "_#{key.to_s.titleize}_: #{value}"
            end.join("\n")
          end

          def pending_redemptions_info
            return if pending_redemptions.blank?

            pending_redemptions.map do |redemption|
              "- _Id_: #{redemption.id}, _Company_: #{redemption.company.domain}, _Reward id_: #{redemption.reward_id}"
            end.prepend(":warning: *Intervention required!* :warning:").join("\n")
          end

          def relevant_rewards_info
            relevant_rewards.map do |reward|
              reward_was_disabled = rewards_to_disable.map(&:id).include?(reward.id)
              action_taken = "(_Action taken_: Disabled!, _Reason_: None of the variants is_enabled anymore.)" if reward_was_disabled
              "- _Id_: #{reward.id}, _Title_: #{reward.title}, _Company_: #{reward.company.domain} #{action_taken}"
            end.join("\n")
          end

          def none_text
            "_None_"
          end

          def blocks
            [
              section(text: ":information_source: *#{subject}* :information_source:"),
              divider,
              section(text: " *Provider reward variant*:\n#{provider_reward_variant_info}"),
              divider,
              section(text: " *Active rewards that use the variant*:\n#{relevant_rewards_info.presence || none_text}"),
              divider,
              section(text: " *Pending redemptions that redeem the variant*:\n#{pending_redemptions_info.presence || none_text}"),
              divider
            ]
          end
        end
      end
    end
  end
end
