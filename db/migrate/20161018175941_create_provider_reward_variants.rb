class CreateProviderRewardVariants < ActiveRecord::Migration[4.2]
  def change
    create_table :provider_reward_variants do |t|
      t.string :provider_key
      t.string :name
      t.string :currency_code
      t.string :status
      t.string :value_type
      t.string :reward_type
      t.decimal :face_value, precision: 10, scale: 2
      t.decimal :min_value, precision: 10, scale: 2
      t.decimal :max_value, precision: 10, scale: 2
      t.string :countries
      t.integer(:provider_reward_id, null: false)
      t.timestamps
    end
  end
end