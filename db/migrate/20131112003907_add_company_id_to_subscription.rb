class AddCompanyIdToSubscription < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :company_id, :integer
  end
end
