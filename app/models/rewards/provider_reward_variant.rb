# frozen_string_literal: true

module Rewards
  class ProviderRewardVariant < ApplicationRecord
    belongs_to :provider_reward, optional: true
    has_many :reward_variants, inverse_of: :provider_reward_variant

    default_scope { order(face_value: :asc) }
    scope :active, -> { where(status: "active") }

    after_commit :handle_status_change_to_disabled, if: :status_changed_to_disabled?

    def points(catalog)
      Reward.convert_currency_to_points(self.face_value, catalog.points_to_currency_ratio)
    end

    private

    def handle_status_change_to_disabled
      Rewards::ProviderSyncDeviation::ProviderRewardVariant::StatusChangeHandler.delay(queue: 'priority_caching').handle(self.id)
    end

    def status_changed_to_disabled?
      self.status_previously_changed? && self.status == "disabled"
    end
  end
end
