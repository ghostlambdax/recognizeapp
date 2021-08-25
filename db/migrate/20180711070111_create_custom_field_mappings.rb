class CreateCustomFieldMappings < ActiveRecord::Migration[5.0]
  def change
    create_table :custom_field_mappings do |t|
      t.integer :company_id
      t.string :key
      t.string :name
      t.string :provider_key
    end
  end
end
