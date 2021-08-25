class AddSubdomainToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :subdomain, :string
  end
end
