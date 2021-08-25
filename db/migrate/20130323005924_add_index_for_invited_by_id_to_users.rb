class AddIndexForInvitedByIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :invited_by_id
  end
end
