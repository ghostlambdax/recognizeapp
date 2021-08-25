class AddForceSsoToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :force_sso, :boolean, default: true
  end
end
