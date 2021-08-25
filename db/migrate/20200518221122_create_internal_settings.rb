class CreateInternalSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :internal_settings do |t|
      t.string :key
      t.string :value
      t.text :description
      t.timestamps
    end
  end
end
