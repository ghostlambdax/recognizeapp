class UpdateSubscriptionsToHaveCompanyId < ActiveRecord::Migration[4.2]
  def up
    Subscription.all.each do |s|
      s.update_attribute(:company_id, s.user.company_id)
    end
  end

  def down
  end
end
