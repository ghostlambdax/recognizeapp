class CompanyAdmin::RedemptionsController < CompanyAdmin::BaseController
  layout "rewards_admin"

  def index
    @datatable = RewardsRedemptionsDatatable.new(view_context, @company)

    gon.redemption_additional_instructions_input_placeholder= t('redemption.additional_instructions_for_user_input_placeholder')
    gon.redemption_additional_instructions_title = t('redemption.additional_instructions_for_user_title')
    respond_with(@datatable)
  end

end
