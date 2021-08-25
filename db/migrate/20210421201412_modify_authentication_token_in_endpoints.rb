# Change column name/type for auth token to store encrypted value (using the toolbox gem)
# Note: Data migration is not needed here because this branch hasn't been deployed anywhere at this point
class ModifyAuthenticationTokenInEndpoints < ActiveRecord::Migration[6.0]
  def change
    add_column :webhook_endpoints, :authentication_token_ciphertext, :text
    remove_column :webhook_endpoints, :authentication_token, :string
  end
end
