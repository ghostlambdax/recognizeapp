class AddUnclaimedTokensTable < ActiveRecord::Migration[5.0]
  def change
    create_table :fb_workplace_unclaimed_tokens do |t|
      t.string :community_id
      t.text :token
      t.timestamps
    end

  end
end
