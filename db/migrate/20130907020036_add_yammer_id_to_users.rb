class AddYammerIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :yammer_id, :integer
  end
end
