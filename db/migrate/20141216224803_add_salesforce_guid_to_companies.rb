class AddSalesforceGuidToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :salesforce_guid, :text
  end
end
