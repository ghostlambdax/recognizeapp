class AddActiveFieldToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :disabled_at, :datetime
  end
end
