class AddUpnColumnToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :user_principal_name, :string
    add_column :company_settings, :authentication_field, :integer, default: 0
  end
end
