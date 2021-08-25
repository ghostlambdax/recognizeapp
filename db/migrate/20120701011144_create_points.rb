class CreatePoints < ActiveRecord::Migration[4.2]
  def change
    create_table :points do |t|
      t.integer :giver_id
      t.integer :recognition_id

      t.timestamps
    end
  end
end
