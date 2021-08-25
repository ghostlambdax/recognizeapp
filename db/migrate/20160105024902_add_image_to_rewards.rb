class AddImageToRewards < ActiveRecord::Migration[4.2]
  def change
    add_column :rewards, :image, :string
  end
end
