class CompanyAdmin::RewardsTransactionsController < CompanyAdmin::BaseController
  layout "rewards_admin"

  def index
    @datatable = RewardsTransactionsDatatable.new(view_context, @company)
    if @company.primary_funding_account
      balance = @company.primary_funding_account.balance.to_f.round(2)
      gon.balance_info = I18n.t('company_admin.rewards.transactions.balance_available',
                                balance: "$#{balance}")
    end
    respond_with(@datatable)
  end
end
