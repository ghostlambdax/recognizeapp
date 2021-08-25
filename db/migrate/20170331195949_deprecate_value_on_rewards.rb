class DeprecateValueOnRewards < ActiveRecord::Migration[4.2]
  def change
    # value will always be on the variant
    rename_column :rewards, :value, :deprecated_value
    add_column :reward_variants, :label, :string
    change_column :reward_variants, :provider_reward_variant_id, :integer, null: true
  end
end
