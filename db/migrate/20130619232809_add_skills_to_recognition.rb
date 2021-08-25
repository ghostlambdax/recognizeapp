class AddSkillsToRecognition < ActiveRecord::Migration[4.2]
  def change
    add_column :recognitions, :skills, :text
  end
end
