# frozen_string_literal: true

class Api::V2::Endpoints::Rewards < Api::V2::Base
  include Api::V2::Defaults

  class Entity < Api::V2::Entities::Base
    include ::UsersHelper
    include MoneyRails::ActionViewExtension
    include ::RedemptionsHelper

    root 'rewards', 'reward'

    expose :variants
    expose :title
    expose :quantity_remaining
    expose :image_url
    expose :description
    expose :lowest_variant
    expose :restricted_by_user_limit?, as: :restricted_by_user_limit
    expose :restricted_by_quantity?, as: :restricted_by_quantity
    expose :id
    expose :quantity
    expose :reward_type
    expose :point_conversion
    expose :availability_status

    def availability_status
      return nil unless current_user.present?
      reward_availability_status(object, current_user)
    end

    def point_conversion
      object.catalog.points_to_currency_ratio
    end

    def variants
      object.variants.enabled.map do |v| variant_object(v) end
    end

    def lowest_variant
      variant_object(object.lowest_variant)
    end

    private
      def variant_object(variant)
        variant_availability_status = current_user.present? ? 
          reward_variant_availability_status(variant, current_user) : 
          nil
        {
          id: variant.id,
          face_value: variant.face_value,
          label: variant.label,
          quantity: variant.quantity,
          availability_status: variant_availability_status
        }
      end
  end

  mount Api::V2::Endpoints::Rewards::Index
end
