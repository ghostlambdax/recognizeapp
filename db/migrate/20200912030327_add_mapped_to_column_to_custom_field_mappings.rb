class AddMappedToColumnToCustomFieldMappings < ActiveRecord::Migration[5.0]
  def change
    add_column :custom_field_mappings, :mapped_to, :string
  end
end
