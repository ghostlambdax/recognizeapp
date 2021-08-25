module Rewards
  class RewardVariant < ApplicationRecord

    belongs_to :reward, inverse_of: :variants, optional: true
    belongs_to :provider_reward_variant, inverse_of: :reward_variants, optional: true
    has_many :redemptions, inverse_of: :reward_variant

    validates :face_value, :label, presence: true
    validates :provider_reward_variant_id, presence: true, if: ->{ self.reward.provider_reward? }
    validates :face_value, numericality: {greater_than: 0}, allow_blank: true
    validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_blank: true
    validates :quantity, absence: true, if: :provider_variant?
    validate :face_value_is_proper, if: :provider_variant?
    validate :quantity_is_greater_than_number_of_redemptions

    before_validation :set_face_value_from_provider_variant, if: ->{ self.reward.discrete_provider_reward? }
    before_validation :set_label, if: :provider_variant?

    scope :enabled, ->{ where(is_enabled: true) }

    def points
      Reward.convert_currency_to_points(self.face_value, self.reward.catalog).to_i
    end

    def provider_variant?
      reward && reward.provider_reward? && self.provider_reward_variant_id.present?
    end

    def quantity_remaining
      self.quantity && (
        self.quantity - existing_company_redemptions_count_in_interval
      )
    end

    def can_redeem_within_quantity?
      return true if self.quantity.nil?
      quantity_remaining > 0
    end

    def existing_company_redemptions_count_in_interval
      redemptions = self.reward.company.redemptions.not_denied.where(reward_variant_id: self.id)

      if self.reward.quantity_interval.null?
        redemptions.size
      else
        redemptions.where("created_at > ?", self.reward.quantity_interval.start).size
      end
    end

    private

    def quantity_is_greater_than_number_of_redemptions
      return if self.quantity.nil?
      return unless quantity_remaining < 0
      self.errors.add(:quantity, I18n.t("activerecord.errors.models.reward.greater_than_quantity_redeemed"))
    end

    # enforce label for provider rewards
    def set_label
      return if face_value.blank?

      relevant_currency_symbol = begin
        relevant_currency_code = self.provider_reward_variant.currency_code
        Rewards::Currency.get_money_currency(relevant_currency_code).symbol
      end
      self.label = "#{relevant_currency_symbol}#{face_value}".no_zeros
    end

    def set_face_value_from_provider_variant
      self.face_value = self.provider_reward_variant.face_value
    end

    def face_value_is_proper
      return unless face_value.present?
      return unless face_value > 0 # <0 is handled by numericality validation

      provider_reward = self.provider_reward_variant.provider_reward

      if reward.discrete_provider_reward?
        # is included in set discrete values
        unless provider_reward.discrete_values.include?(face_value)
          errors.add(:face_value, "is not valid")
        end
      else
        # is within min/max
        if face_value < provider_reward.min_value
          errors.add(:face_value, "is too low")
        elsif face_value > provider_reward.max_value
          errors.add(:face_value, "is too high")
        end

      end
    end
  end
end
