class AddColumnsToCustomFieldMappings < ActiveRecord::Migration[5.0]
  def change
    add_column :custom_field_mappings, :provider_type, :string
    add_column :custom_field_mappings, :provider_attribute_key,  :string
  end
end
