class AddSkuToRewards < ActiveRecord::Migration[4.2]
  def change
    add_column :rewards, :sku, :text
    add_column :rewards, :status, :string, default: "funded"
  end
end
