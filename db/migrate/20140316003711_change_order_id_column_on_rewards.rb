class ChangeOrderIdColumnOnRewards < ActiveRecord::Migration[4.2]
  def up
    change_column :rewards, :order_id, :string
  end

  def down
  end
end
