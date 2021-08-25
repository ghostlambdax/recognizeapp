class AddManagerIdToRewards < ActiveRecord::Migration[4.2]
  def change
    add_column :rewards, :manager_id, :integer
  end
end
