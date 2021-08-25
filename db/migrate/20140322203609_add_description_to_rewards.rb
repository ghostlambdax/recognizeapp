class AddDescriptionToRewards < ActiveRecord::Migration[4.2]
  def change
    add_column :rewards, :description, :string
  end
end
