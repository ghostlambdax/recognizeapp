class AddUniqueIndexToFundsTxn < ActiveRecord::Migration[4.2]
  def up
    add_column :funds_txns, :non_unique_key, :integer
    Rewards::FundsTxn.reset_column_information

    # add special flag that allows non-unique rows for the redemptions
    # that inadvertantly were duped
    redemption_data = {3338=>3, 3340=>2, 3407=>2, 3521=>2, 3546=>2, 3567=>2, 3568=>2, 3570=>2, 4029=>2, 4431=>2, 4838=>2, 4860=>2}
    redemption_ids = redemption_data.keys
    redemptions = Redemption.where(id: redemption_ids)

    if redemptions.length > 0
      txns = Rewards::FundsTxn.where(funds_txnable_id: redemption_ids)
      groups = txns.group_by{|txn| "#{txn.funds_account_id}-#{txn.funds_txnable_id}"}
      groups.each do |key, redemption_fund_transactions|
        _funds_account_id, redemption_id = key.split("-")
        if redemption_id == "3338"
          redemption_fund_transactions.last(2).each_with_index{|r,i| r.update_column(:non_unique_key, i)}
        else
          redemption_fund_transactions.last.update_column(:non_unique_key, 1)
        end
      end
    end

    add_index :funds_txns, [:funds_account_id, :txn_type, :funds_txnable_id, :funds_txnable_type, :non_unique_key], unique: true, name: 'funds_txn_uniq_constraint'
  end
end
