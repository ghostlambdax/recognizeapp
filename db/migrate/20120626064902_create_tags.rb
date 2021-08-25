class CreateTags < ActiveRecord::Migration[4.2]
  def change
    create_table :tags do |t|
      t.string :name
      t.string :short_name
      t.string :long_name
      t.timestamps
    end
  end
end
