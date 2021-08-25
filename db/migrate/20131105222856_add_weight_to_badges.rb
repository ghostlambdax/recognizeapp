class AddWeightToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :points, :integer
  end
end
