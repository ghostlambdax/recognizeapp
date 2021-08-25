# frozen_string_literal: true

class CompanyAdmin::Anniversaries::CalendarsController < CompanyAdmin::Anniversaries::BaseController
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
    UsersAnniversaryDatatable.new(view_context, @company)
  end
end
