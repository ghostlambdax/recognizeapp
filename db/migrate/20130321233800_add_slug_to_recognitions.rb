class AddSlugToRecognitions < ActiveRecord::Migration[4.2]
  def change
    add_column :recognitions, :slug, :string
  end
end
