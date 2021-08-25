# This class just "resets points" by simply making
# all unredeemed/redeemable points no longer redeemable
# It does not change redemption history
# To do a full reset of redemption history, I would just blow away
# + recognitions
# + rewards
# + point activities
# + redemptions
class Rewards::PointsResetter
  attr_reader :company, :user

  def self.reset!(company, user)
    new(company, user).reset!
  end

  def initialize(company, user)
    @company = company
    @user = user
  end

  def reset!
    reset_activities    
    reset_counter_cache
  end

  private
  def reset_activities
    PointActivity
      .where(company_id: company.id)
      .where(is_redeemable: true)
      .update_all(is_redeemable: false, reset_at: Time.now, reset_by_id: user.id)
  end

  def reset_counter_cache
    company.users.each do |user|
      user.update_redeemable_points!
    end
  end
end