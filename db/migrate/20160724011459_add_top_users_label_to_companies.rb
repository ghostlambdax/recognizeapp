class AddTopUsersLabelToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :labels, :text
  end
end
