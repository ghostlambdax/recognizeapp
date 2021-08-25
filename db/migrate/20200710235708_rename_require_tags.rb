class RenameRequireTags < ActiveRecord::Migration[5.0]
  def change
    rename_column :company_settings, :require_tags, :require_recognition_tags
  end
end
