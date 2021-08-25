class MigrateRedemptionsToNewVariantModel < ActiveRecord::Migration[4.2]
  def up
    puts "Migrating Redemptions to new variant model"
    Redemption.all.each do |r|
      print "."
      r.update_column(:reward_variant_id, r.reward.variants.first.id)
    end
  end
end
