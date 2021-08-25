class AddDefaultToAccountBalance < ActiveRecord::Migration[4.2]
  def change
    change_column :funds_accounts, :balance, :decimal, precision: 10, scale: 2, default: 0
  end
end
