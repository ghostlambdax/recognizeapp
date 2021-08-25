class AddRoleToRoles < ActiveRecord::Migration[4.2]
  def up
    Role.create :name => "system_user" rescue nil
  end
end
