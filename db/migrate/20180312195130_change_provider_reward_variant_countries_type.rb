class ChangeProviderRewardVariantCountriesType < ActiveRecord::Migration[4.2]
  def change
    change_column :provider_reward_variants, :countries, :text
  end
end
