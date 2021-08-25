class CreateSurveys < ActiveRecord::Migration[4.2]
  def change
    create_table :surveys do |t|
      t.string :data
      t.string :email

      t.timestamps
    end
  end
end
