class FixUserCompanyRoles < ActiveRecord::Migration[4.2]
  def change
    rename_column(:user_company_roles, :company_id, :company_role_id)
  end
end
