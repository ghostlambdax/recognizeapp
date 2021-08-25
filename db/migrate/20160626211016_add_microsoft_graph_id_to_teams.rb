class AddMicrosoftGraphIdToTeams < ActiveRecord::Migration[4.2]
  def change
    add_column :teams, :microsoft_graph_id, :string
  end
end
