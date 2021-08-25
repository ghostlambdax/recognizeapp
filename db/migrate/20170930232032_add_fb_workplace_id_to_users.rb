class AddFbWorkplaceIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :fb_workplace_id, :string
  end
end
