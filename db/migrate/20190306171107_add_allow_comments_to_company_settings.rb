class AddAllowCommentsToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :allow_comments, :boolean, default: true
  end
end
