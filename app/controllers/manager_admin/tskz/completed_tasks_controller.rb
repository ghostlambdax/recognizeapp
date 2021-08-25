class ManagerAdmin::Tskz::CompletedTasksController < ManagerAdmin::BaseController
  def index
    @datatable = ManagerAdmin::Tskz::CompletedTasksDatatable.new(view_context, @company)
    respond_with(@datatable)
  end

end
