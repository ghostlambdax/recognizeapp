class CompanyAdmin::Tskz::TasksController < CompanyAdmin::BaseController
  layout "tasks_admin"
  def index
    @datatable = ::Tskz::TasksDatatable.new(view_context, company)
    respond_with(@datatable)
  end

  def new
    @task = company.tasks.new
    @company_roles = company.company_roles
    @tags = company.tags.task_taggable
  end

  def edit
    @task = company.tasks.find(params[:id])
    @company_roles = company.company_roles
    @tags = company.tags.task_taggable
  end

  def create
    @task = company.tasks.build(tasks_params)
    if @task.valid? && @task.save_with_options
      flash[:notice] = t("tskz.task.successfully_created")
      respond_with(@task, location: company_admin_tasks_path)
    else
      @company_roles = company.company_roles
      @tags = company.tags
      respond_with @task
    end
  end

  def update
    @task = company.tasks.find(params[:id])
    @task.assign_attributes(tasks_params)
    if @task.valid? && @task.save_with_options
      flash[:notice] = t("tskz.task.successfully_updated")
      respond_with(@task, location: company_admin_tasks_path)
    else
      @company_roles = company.company_roles
      @tags = company.tags
      respond_with @task
    end
  end

  def destroy
    @task = company.tasks.find(params[:id])
    if @task.has_completed_tasks?
      @task.toggle_status
    else
      @task.destroy
    end
  end
  private

  def company
    @company
  end

  def tasks_params
    params.require(:tskz_task).permit(:name, :points, :tag_name, :company_roles => [])
  end
end
