class AddRecognitionWysiwygEditorEnabledToCompanies < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :recognition_wysiwyg_editor_enabled, :boolean, default: true
  end
end
