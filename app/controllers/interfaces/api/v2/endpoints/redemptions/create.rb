# frozen_string_literal: true

class Api::V2::Endpoints::Redemptions::Create < Api::V2::Endpoints::Redemptions
  resource :redemptions, desc: '' do
    desc 'Create a redemption' do
      # success Api::V2::Endpoints::Redemptions::Entity
    end

    params do
      requires :reward_id, desc: "Reward ID"
      requires :variant_id, desc: "Variant of the reward, such as $5 card vs $10 card."
    end

    oauth2 'write'
    post '/' do
      reward = current_user.company.rewards.find(unhash(params[:reward_id])).first
      variant = reward.variants.find(params[:variant_id])
      redemption = Redemption.redeem(current_user, variant, api_viewer_attributes)
      present redemption
    end
  end
end
