class AddShowSkillsAsSettingToCompany < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :show_skills, :boolean, default: false
  end
end
