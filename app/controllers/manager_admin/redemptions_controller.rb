class ManagerAdmin::RedemptionsController < ManagerAdmin::BaseController
  before_action :set_redemption, only: [:approve, :deny]

  def index
    @datatable = ManagerAdmin::RewardsRedemptionsDatatable.new(view_context, @company)
    gon.redemption_additional_instructions_input_placeholder= t('redemption.additional_instructions_for_user_input_placeholder')
    gon.redemption_additional_instructions_title = t('redemption.additional_instructions_for_user_title')

    respond_with(@datatable)
  end

  def approve
    @redemption.approve(approver: current_user, additional_instructions: params[:redemption_additional_instructions], request_form_id: params[:request_form_id])

    render "company_admin/rewards/approve_redemption"
  end

  def deny
    @redemption.deny(denier: current_user)
    render "company_admin/rewards/deny_redemption"
  end

  private

  def set_redemption
    @redemption = @company.redemptions.find(params[:id])
  end
end
