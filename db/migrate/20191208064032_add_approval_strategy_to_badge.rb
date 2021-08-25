class AddApprovalStrategyToBadge < ActiveRecord::Migration[5.0]
  def change
    add_column :badges, :approval_strategy, :integer
  end
end
