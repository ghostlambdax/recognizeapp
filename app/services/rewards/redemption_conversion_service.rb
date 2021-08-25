# The idea here is to allow companies to reset the face value of redemptions
# based upon a new ratio
# Normally, changing a points_to_currency ratio is not retroactive
# but for launch, since we don't know the ratio ahead of time, 
# we let companies set the ratio and then retroactively 
# update the redemptions and associated data models to the proper values
class Rewards::RedemptionConversionService
  attr_reader :catalog, :force

  def initialize(catalog, force: false)
    @catalog = catalog
    @force = force
  end

  def company
    catalog.company
  end

  def set_ratio!(ratio)

    Company.transaction do
      catalog.update_column(:points_to_currency_ratio, ratio)

      # migrate company fulfilled rewards
      catalog.reward_variants.company_fulfilled.find_each do |variant|
        # reset the face value of each variant of company fulfilled reward
        # based on its points
        variant.face_value = variant.face_value / catalog.points_to_currency_ratio
        variant.save!
      end

      # migrate old redemptions to this ratio
      catalog.redemptions.find_each do |redemption|
        redemption.update_columns(value_redeemed: redemption.reward_variant.face_value)
      end

      # update all user points
      # user_ids = Redemption.all.select(:user_id).pluck(:user_id).uniq
      # User.where(id: user_ids).each do |u|
      #   puts "Calculating redeemable points for #{u.email}(#{u.id})"
      #   u.update_redeemed_points!
      # end

    end
  end
end