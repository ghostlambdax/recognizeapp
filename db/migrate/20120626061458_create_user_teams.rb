class CreateUserTeams < ActiveRecord::Migration[4.2]
  def change
    create_table :user_teams do |t|
      t.integer :user_id
      t.integer :team_id
      t.timestamps
    end
  end
end
