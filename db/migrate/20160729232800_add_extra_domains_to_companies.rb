class AddExtraDomainsToCompanies < ActiveRecord::Migration[4.2]
  def change
    create_table :company_domains do |t|
      t.integer :company_id, null: false
      t.string :domain, null: false
    end
  end
end
