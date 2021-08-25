class CreateFundsAccountManualAdjustments < ActiveRecord::Migration[4.2]
  def change
    create_table :funds_account_manual_adjustments do |t|
      t.decimal :amount, precision: 10, scale: 2

      t.timestamps
    end
  end
end
