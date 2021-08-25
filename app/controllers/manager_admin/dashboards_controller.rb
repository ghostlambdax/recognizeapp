class ManagerAdmin::DashboardsController < ManagerAdmin::BaseController
  before_action :stub_dashboard, only: :show

  def show
  end

  private

  # until we fill out dashboard, redirect to a 'home'
  # based upon role
  def stub_dashboard
    case
    when current_user.rewards_manager? && !current_user.manager?
      redirect_to manager_admin_redemptions_path
    else
      redirect_to manager_admin_users_path
    end
    return false
  end
end