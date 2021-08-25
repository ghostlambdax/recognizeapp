class AddUniqueConstraintToUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :unique_key, :string
    add_index :users, :unique_key, unique: true

    User.reset_column_information
    # require File.join(Rails.root, 'db/merge_users')

  end

  def down
    remove_column :users, :unique_key
  end
end
