class CreateAuthenticationsTable < ActiveRecord::Migration[4.2]
  def change
    create_table :authentications do |t|
      t.integer :user_id
      t.string :provider
      t.string :uid
      t.timestamps
    end
  end
end
