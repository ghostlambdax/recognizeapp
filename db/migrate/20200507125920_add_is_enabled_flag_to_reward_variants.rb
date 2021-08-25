class AddIsEnabledFlagToRewardVariants < ActiveRecord::Migration[5.0]
  def change
    add_column :reward_variants, :is_enabled, :boolean, default: true
  end
end
