class ExistingCompaniesDisableRewards < ActiveRecord::Migration[4.2]
  def change
    Company.update_all(allow_rewards: false)
  end
end
