class AddCompanyIdDataToUserRoles < ActiveRecord::Migration[4.2]
  def up
    user_roles = UserRole.joins(:user).select('user_roles.id, user_roles.user_id, users.company_id')
    count = user_roles.length
    user_roles.each_with_index do |ur, index|
      puts "Updating user role #{index}/#{count}"
      ur.update_column(:company_id, ur.company_id)
    end
  end
end
