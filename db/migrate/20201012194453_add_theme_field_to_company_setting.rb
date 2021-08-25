class AddThemeFieldToCompanySetting < ActiveRecord::Migration[5.0]
  def change
    add_column :company_customizations, :stylesheet, :text
  end
end
