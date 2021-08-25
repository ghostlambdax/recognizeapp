class AddSamlAttributesToConfiguration < ActiveRecord::Migration[4.2]
  def change
    add_column :saml_configurations, :first_name_uri, :string
    add_column :saml_configurations, :last_name_uri, :string
  end
end
