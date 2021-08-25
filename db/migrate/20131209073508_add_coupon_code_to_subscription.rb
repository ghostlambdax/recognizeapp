class AddCouponCodeToSubscription < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :coupon_code, :string
  end
end
