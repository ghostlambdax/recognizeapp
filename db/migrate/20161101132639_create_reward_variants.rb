class CreateRewardVariants < ActiveRecord::Migration[4.2]
  def change
    create_table :reward_variants do |t|
      t.decimal :face_value, precision: 32, scale: 2
      t.integer :reward_id, null: false
      t.integer :provider_reward_variant_id, null: false
      t.timestamps
    end

    # had to update precision on reward variants so take care of the others
    [
      [:funds_account_manual_adjustments, :amount],
      [:funds_accounts, :balance],
      [:funds_txns, :amount],
      [:funds_txns, :resulting_balance]
    ].each do |(table, attr)|
      change_column table, attr, :decimal, precision: 32, scale: 2
    end
  end
end
