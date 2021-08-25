class UpdateSystemUserName < ActiveRecord::Migration[4.2]
  def up
    User.system_user.update_attribute(:last_name, "Team") if User.system_user.present?
  end

  def down
  end
end
