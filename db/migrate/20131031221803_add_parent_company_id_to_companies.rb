class AddParentCompanyIdToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :parent_company_id, :integer
  end
end
