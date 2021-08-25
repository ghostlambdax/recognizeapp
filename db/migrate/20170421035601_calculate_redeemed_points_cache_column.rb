class CalculateRedeemedPointsCacheColumn < ActiveRecord::Migration[4.2]
  def up
    User.reset_column_information
    user_ids = Redemption.all.select(:user_id).pluck(:user_id).uniq
    User.where(id: user_ids).each do |u|
      puts "Calculating redeemable points for #{u.email}(#{u.id})"
      u.update_redeemed_points!
    end
  end
end
