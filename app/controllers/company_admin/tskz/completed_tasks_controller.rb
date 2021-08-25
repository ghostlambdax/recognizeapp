class CompanyAdmin::Tskz::CompletedTasksController < CompanyAdmin::BaseController
  layout "tasks_admin"
  def index
    @datatable = ::Tskz::CompletedTasksDatatable.new(view_context, @company)
    respond_with(@datatable)
  end

end
