class AddInvitationFieldsToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :invited_by_id, :integer
    add_column :users, :invited_at, :datetime
  end
end
