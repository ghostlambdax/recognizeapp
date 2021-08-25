class ManagerAdmin::UsersController < ManagerAdmin::BaseController
  def index
    @users = current_user.employees.not_disabled
  end
end