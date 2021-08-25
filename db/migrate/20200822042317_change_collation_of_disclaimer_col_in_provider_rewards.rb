class ChangeCollationOfDisclaimerColInProviderRewards < ActiveRecord::Migration[5.0]
  def change
    change_column :provider_rewards, :disclaimer, :text, collation: :utf8mb4_unicode_ci
  end
end
