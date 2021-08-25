class CreateBadges < ActiveRecord::Migration[4.2]
  def change
    create_table :badges do |t|
      t.string :name
      t.string :short_name
      t.string :long_name
      t.text :description
      t.timestamps
    end
  end
end
