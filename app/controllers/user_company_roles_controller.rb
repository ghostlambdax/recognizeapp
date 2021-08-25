class UserCompanyRolesController < ApplicationController
  def create
    user.company_roles.add(role)
    head :ok
  end

  def destroy
    user.company_roles.remove(role)
    head :ok
  end

  private

  def user
    @user ||= company.users.find(params[:user_id])
  end

  def role
    @role ||= company.company_roles.find_by(id: params[:role_id])
  end

  def company
    @company
  end
end
