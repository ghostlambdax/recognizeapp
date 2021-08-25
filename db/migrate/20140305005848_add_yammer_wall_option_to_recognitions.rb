class AddYammerWallOptionToRecognitions < ActiveRecord::Migration[4.2]
  def change
    add_column :recognitions, :post_to_yammer_wall, :boolean, default: false
  end
end
