class CreateFundsAccounts < ActiveRecord::Migration[4.2]
  def change
    create_table :funds_accounts do |t|
      t.decimal :balance, precision: 10, scale: 2

      t.timestamps
    end
  end
end
