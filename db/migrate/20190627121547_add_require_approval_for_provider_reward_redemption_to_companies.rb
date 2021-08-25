class AddRequireApprovalForProviderRewardRedemptionToCompanies < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :require_approval_for_provider_reward_redemptions, :boolean, default: true
  end
end
