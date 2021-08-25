class AddRequireTagsToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :require_tags, :boolean, default: false
  end
end
