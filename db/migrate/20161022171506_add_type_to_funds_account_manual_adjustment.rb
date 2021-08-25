class AddTypeToFundsAccountManualAdjustment < ActiveRecord::Migration[4.2]
  def change
    add_column :funds_account_manual_adjustments, :type, :string
  end
end
