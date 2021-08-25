class AddLowBalanceThresholdToCompanySetting < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :low_balance_threshold, :integer
  end
end
