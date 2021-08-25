class EnsureAllUsersHaveRoles < ActiveRecord::Migration[4.2]
  def up
    User.with_deleted.all.select{|u| u.roles.blank?}.each{|u| u.roles << Role.employee}
  end
end
