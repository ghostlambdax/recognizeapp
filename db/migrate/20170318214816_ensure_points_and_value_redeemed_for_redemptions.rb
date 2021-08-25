class EnsurePointsAndValueRedeemedForRedemptions < ActiveRecord::Migration[4.2]
  def up
    Redemption.reset_column_information
    Redemption.all.each do |redemption|
      redemption.points_redeemed = redemption.reward.deprecated_points
      redemption.value_redeemed = (redemption.reward.provider_reward? ? redemption.provider_face_value : redemption.reward.value)
      redemption.save!(validate: false)
    end
  end
end
