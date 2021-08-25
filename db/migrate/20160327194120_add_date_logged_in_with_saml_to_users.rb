class AddDateLoggedInWithSamlToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :last_auth_with_saml_at, :datetime
  end
end
