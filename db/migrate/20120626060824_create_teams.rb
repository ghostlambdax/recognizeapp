class CreateTeams < ActiveRecord::Migration[4.2]
  def change
    create_table :teams do |t|
      t.integer :company_id
      t.string :name
      t.timestamps
    end
  end
end
