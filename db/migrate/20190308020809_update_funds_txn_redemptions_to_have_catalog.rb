class UpdateFundsTxnRedemptionsToHaveCatalog < ActiveRecord::Migration[5.0]
  def up
    base_query = Rewards::FundsTxn
      .joins("INNER JOIN redemptions ON funds_txns.funds_txnable_id=redemptions.id INNER JOIN rewards ON redemptions.reward_id=rewards.id INNER JOIN catalogs ON rewards.catalog_id=catalogs.id")
      .where("funds_txns.funds_txnable_type='Redemption'")

    base_query.update_all("funds_txns.catalog_id=rewards.catalog_id")    
    base_query.update_all("funds_txns.amount_currency_code=catalogs.currency")    

    Rewards::FundsAccount.update_all(currency_code: 'USD')
  end
end
