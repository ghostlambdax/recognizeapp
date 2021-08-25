class AddAdditionalCustomizations < ActiveRecord::Migration[4.2]
  def change
    add_column :company_customizations, :youtube_id, :string
    add_column :company_customizations, :action_text_color, :string
  end
end
