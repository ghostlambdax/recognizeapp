class MigrateRewardsFixedValueToVariant < ActiveRecord::Migration[4.2]
  def up
    Reward.reset_column_information
    puts "Migrating Rewards#(deprecated)value to reward variants model"
    Reward.all.each do |r|
      print ".(#{r.id})"+(Rails.env.development? ? "(#{r.deprecated_value})" : '')
      begin
        r.variants.create!(face_value: r.deprecated_value, label: r.title)
      rescue => e
        Rails.logger.error "Could not create variant for reward(#{r.id}) - #{r.title}"
        Rails.logger.error "Error: #{e.message}"
      end
    end
  end
end
