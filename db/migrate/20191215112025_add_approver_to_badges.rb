class AddApproverToBadges < ActiveRecord::Migration[5.0]
  def change
    add_column :badges, :approver, :integer
  end
end
