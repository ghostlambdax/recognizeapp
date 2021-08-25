class AddAnniversaryTemplateIdToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :anniversary_template_id, :string
  end
end
