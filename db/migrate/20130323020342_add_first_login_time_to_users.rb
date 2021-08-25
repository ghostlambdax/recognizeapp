class AddFirstLoginTimeToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :first_login_at, :datetime
  end
end
