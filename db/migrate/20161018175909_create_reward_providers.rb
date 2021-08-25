class CreateRewardProviders < ActiveRecord::Migration[4.2]
  def change
    create_table :reward_providers do |t|
      t.string :name
      t.timestamps
    end

  end
end
