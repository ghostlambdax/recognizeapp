class AddAdjustmentTypeToFundsAccountManualAdjustment < ActiveRecord::Migration[4.2]
  def change
    add_column :funds_account_manual_adjustments, :adjustment_type, :string
  end
end
