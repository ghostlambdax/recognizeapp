class AddProviderCredentialsToAuthentications < ActiveRecord::Migration[4.2]
  def change
    add_column :authentications, :credentials, :text
  end
end
