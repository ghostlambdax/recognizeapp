class CompanyAdmin::PointsController < CompanyAdmin::BaseController
  include ServerSideExportConcern
  layout "points_admin"

  def summary
    respond_with(datatable)
  end

  def index
    respond_with(datatable)
  end

  def show
    respond_with(datatable)
  end

  private

  def datatable
    action = params[:exporter_action] || params[:action]
    @datatable ||= case action.to_s
    when 'summary'
      params[:from] = @company.created_at.to_i
      params[:to] = DateTime.now.to_i
      PointsDatatable.new(view_context, @company)

    when 'index'
      CompanyPointActivitiesDatatable.new(view_context, @company)

    when 'show'
      @user = @company.users.find(params[:id])
      UserPointActivitiesDatatable.new(view_context, @user)
    end
  end
end
