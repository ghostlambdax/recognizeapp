class AddMetadataUrlToSamlConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :saml_configurations, :metadata_url, :string
  end
end
