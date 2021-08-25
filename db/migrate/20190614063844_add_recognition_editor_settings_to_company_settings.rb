class AddRecognitionEditorSettingsToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :recognition_editor_settings, :text
  end
end
