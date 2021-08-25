class RenameIsPublicOnRecognitions < ActiveRecord::Migration[4.2]
  def change
    rename_column :recognitions, :is_public, :is_public_to_world
  end
end
