class CreateDeviceTokens < ActiveRecord::Migration[4.2]
  def change
    create_table :device_tokens do |t|
      t.integer :user_id
      t.text :token
      t.string :platform
    end
  end
end
