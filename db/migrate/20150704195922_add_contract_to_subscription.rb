class AddContractToSubscription < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :contract_title, :string
    add_column :subscriptions, :contract_body, :text
    add_column :subscriptions, :contract_signature, :string
  end
end
