class AddAchievementsSettingToCompany < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :allow_achievements, :boolean, :default => false
  end
end
