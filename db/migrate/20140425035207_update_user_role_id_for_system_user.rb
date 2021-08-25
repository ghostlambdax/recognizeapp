class UpdateUserRoleIdForSystemUser < ActiveRecord::Migration[4.2]
  def change
    UserRole.where(role_id: 5).update_all("role_id=0")
  end
end
