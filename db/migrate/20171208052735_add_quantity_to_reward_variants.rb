class AddQuantityToRewardVariants < ActiveRecord::Migration[4.2]
  def change
    add_column :reward_variants, :quantity, :integer, default: nil
  end
end
