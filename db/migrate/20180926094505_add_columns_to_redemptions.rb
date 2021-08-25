class AddColumnsToRedemptions < ActiveRecord::Migration[5.0]
  def up
    add_column :redemptions, :value_redeemed_currency_code, :string unless column_exists?(:redemptions, :value_redeemed_currency_code)
    add_column :redemptions, :value_redeemed_exchange_rate, :float unless column_exists?(:redemptions, :value_redeemed_exchange_rate)
    add_column :redemptions, :value_redeemed_in_usd, :decimal, precision: 32, scale: 2 unless column_exists?(:redemptions, :value_redeemed_in_usd)

    begin
      # approved provider reward redemption were redeemed in USD
      Redemption.approved.find_each do |redemption|
        if redemption.reward.provider_reward?
          redemption.update_columns(value_redeemed_currency_code: 'USD', value_redeemed_in_usd: redemption.value_redeemed)
        end
      end

      # pending provider reward redemption were redeemed in USD
      Redemption.unapproved.find_each do |redemption|
        if redemption.reward.provider_reward?
          redemption.update_columns(value_redeemed_currency_code: redemption.reward.catalog.currency)
        end
      end
    rescue => e
      Rails.logger.warn "Data migration failed! #{e}" 
    end

  end

  def down
    remove_column :redemptions, :value_redeemed_currency_code
    remove_column :redemptions, :value_redeemed_exchange_rate
    remove_column :redemptions, :value_redeemed_in_usd
  end
end
