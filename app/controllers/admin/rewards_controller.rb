class Admin::RewardsController < Admin::BaseController

  def index
    @datatable = RewardsFundsAccountsDatatable.new(view_context, nil)
    if request.xhr?
      respond_with @datatable
    else
      render action: "index"
    end
  end

  def transactions
    @datatable = RewardsTransactionsAdminDatatable.new(view_context, nil)
    if request.xhr?
      respond_with @datatable
    else
      render action: "transactions"
    end
  end
end
