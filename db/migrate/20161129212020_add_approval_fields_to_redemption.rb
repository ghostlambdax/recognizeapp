class AddApprovalFieldsToRedemption < ActiveRecord::Migration[4.2]
  def change
    add_column :redemptions, :approver_id, :integer
    add_column :redemptions, :approved_at, :datetime
  end
end
