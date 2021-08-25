class SyncCoupons < ActiveRecord::Migration[4.2]
  def up
    unless Rails.env.test?
      Coupon.sync_with_stripe! rescue nil
    end
  end

  def down
  end
end
