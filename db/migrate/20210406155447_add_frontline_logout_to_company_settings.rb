class AddFrontlineLogoutToCompanySettings < ActiveRecord::Migration[6.0]
  def change
    add_column(:company_settings, :frontline_logout, :boolean, default: false)
  end
end
