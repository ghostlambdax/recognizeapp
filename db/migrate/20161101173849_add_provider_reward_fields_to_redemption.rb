class AddProviderRewardFieldsToRedemption < ActiveRecord::Migration[4.2]
  def change
    add_column :redemptions, :provider_reward_variant_id, :integer
    add_column :redemptions, :provider_face_value, :integer
  end
end
