class AddThemeOptionToCompanies < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :has_theme, :boolean, :default => false
  end
end