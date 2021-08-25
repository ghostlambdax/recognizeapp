class RenameShowSkillsToShowRecognitionTags < ActiveRecord::Migration[5.0]
  def change
    rename_column :companies, :show_skills, :show_recognition_tags
    change_column_default :companies, :show_recognition_tags, from: false, to: true
  end
end
