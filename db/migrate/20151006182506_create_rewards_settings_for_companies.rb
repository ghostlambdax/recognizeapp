class CreateRewardsSettingsForCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :allow_rewards, :boolean, default: true
  end
end
