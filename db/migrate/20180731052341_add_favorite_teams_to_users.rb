class AddFavoriteTeamsToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :favorite_team_ids, :text
  end
end
