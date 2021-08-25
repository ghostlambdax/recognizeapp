class AddCompanyIdToCommentsAndApprovals < ActiveRecord::Migration[5.0]
  def change
    add_column :comments, :company_id, :integer
    add_index :comments, :company_id
    add_column :recognition_approvals, :company_id, :integer
    add_index :recognition_approvals, :company_id
  end
end
