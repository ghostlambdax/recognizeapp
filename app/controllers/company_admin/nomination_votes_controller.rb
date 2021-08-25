class CompanyAdmin::NominationVotesController < CompanyAdmin::BaseController
  layout "company_admin"
  respond_to :csv, :xls#, :pdf

  def index
    @datatable = NominationVotesDatatable.new(view_context, @company)
    if request.xhr?
      respond_with @datatable
    else
      render action: "index"
    end    
  end
end