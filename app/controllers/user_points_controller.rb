class UserPointsController < ApplicationController
  include UsersConcern
  before_action :scoped_user

  def index
    @datatable = UserPointActivitiesDatatable.new(view_context, @user)
    respond_with(@datatable)
  end

  private
  def scoped_user
    @user = scoped_company.users.find(params[:user_id])
  end
end
