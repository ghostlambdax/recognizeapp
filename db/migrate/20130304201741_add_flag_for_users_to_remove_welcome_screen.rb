class AddFlagForUsersToRemoveWelcomeScreen < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :has_read_welcome, :boolean, default: false
  end
end
