class UpdateRedemptionsToNewVariantModel < ActiveRecord::Migration[4.2]
  def change
    remove_column :redemptions, :provider_reward_variant_id
    remove_column :redemptions, :provider_face_value
    add_column :redemptions, :reward_variant_id, :integer, null: false
  end
end
