class AddOutlookIdentityTokenToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :outlook_identity_token, :string
  end
end
