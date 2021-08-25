class CreateProviderRewards < ActiveRecord::Migration[4.2]
  def change
    create_table :provider_rewards do |t|
      t.string :provider_key
      t.string :name
      t.text :disclaimer
      t.text :description
      t.text :short_description
      t.text :terms
      t.string :image_url
      t.string :status
      t.integer(:reward_provider_id, null: false)
      t.timestamps
    end
  end
end
