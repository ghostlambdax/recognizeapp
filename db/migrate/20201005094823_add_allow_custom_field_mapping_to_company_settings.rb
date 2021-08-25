class AddAllowCustomFieldMappingToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :allow_custom_field_mapping, :boolean, default: false
  end
end
