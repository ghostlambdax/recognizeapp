class MakeRecognitionsPublicByDefault < ActiveRecord::Migration[4.2]
  def up
    change_column :recognitions, :is_public, :boolean, default: true
  end

  def down
  end
end
