class AddSalesforceGuidToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :salesforce_guid, :string
  end
end
