class CreateCustomizationsModel < ActiveRecord::Migration[4.2]
  def change
    create_table :company_customizations do |t|
      t.integer :company_id
      t.string :primary_bg_color
      t.string :secondary_bg_color
      t.string :primary_text_color
      t.string :secondary_text_color
      t.string :action_color
      t.string :font_family
      t.string :font_url
    end
  end
end
