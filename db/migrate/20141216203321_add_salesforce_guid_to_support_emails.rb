class AddSalesforceGuidToSupportEmails < ActiveRecord::Migration[4.2]
  def change
    add_column :support_emails, :salesforce_guid, :string
  end
end
