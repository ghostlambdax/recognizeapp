class AddEndUserGuideToCustomizations < ActiveRecord::Migration[4.2]
  def change
    add_column :company_customizations, :end_user_guide, :string
  end
end
