class CreateFundsTxns < ActiveRecord::Migration[4.2]
  def change
    create_table :funds_txns do |t|
      t.references :funds_account
      t.string :txn_type
      t.decimal :amount, precision: 10, scale: 2
      t.decimal :resulting_balance, precision: 10, scale: 2
      t.references :funds_txnable, polymorphic: true, index: true

      t.timestamps
    end
  end
end
