class CreateRecognitionTagJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_table :recognition_tags do |t|
      t.string :tag_name, null: false
      t.integer :recognition_id
      t.integer :tag_id

      t.timestamps
    end
    add_index :recognition_tags, [:recognition_id, :tag_id]
  end
end
