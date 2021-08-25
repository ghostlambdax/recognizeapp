class AddViewerToRecognitions < ActiveRecord::Migration[4.2]
  def change
    add_column :recognitions, :viewer, :string
    add_column :recognitions, :viewer_description, :string
  end
end
