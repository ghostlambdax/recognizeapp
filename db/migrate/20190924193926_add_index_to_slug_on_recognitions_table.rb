class AddIndexToSlugOnRecognitionsTable < ActiveRecord::Migration[5.0]
  def change
    add_index :recognitions, :slug
  end
end
