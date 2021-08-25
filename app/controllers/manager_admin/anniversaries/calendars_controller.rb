# frozen_string_literal: true

class ManagerAdmin::Anniversaries::CalendarsController < ManagerAdmin::BaseController
  include ServerSideExportConcern

  def show
    @datatable = datatable
    if request.xhr?
      respond_with @datatable
    else
      render action: "show"
    end
  end

  private
  def datatable
    ManagerAdmin::ManagersAnniversaryDatatable.new(view_context, @company)
  end
end
