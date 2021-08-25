class AddAttributesForMicrosoftGraph < ActiveRecord::Migration[4.2]
  def change
    add_column :authentications, :extra, :text, limit: 4294967295
    add_column :users, :microsoft_graph_id, :string
  end
end
