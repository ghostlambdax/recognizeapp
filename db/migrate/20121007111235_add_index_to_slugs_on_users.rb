class AddIndexToSlugsOnUsers < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :slug
    add_index :companies, :slug
  end
end
