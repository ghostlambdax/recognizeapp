# reset all temporal data such as:
#  - recognitions
#  - point activities
#  - redemptions
#  - tasks
#  - comments
# 
# NOTE: wiping a company's data could have real consequences such as if 
#       the company setup gift cards, redeemed a card, and it was approved
#       then we might break a data dependency between redemptions and funds_txns. 
#       At least, this function will not destroy records from that table. 
#       For now, we will raise error, if there is a gift card redemption
module Utility
  class CompanyResetService
    attr_reader :company, :skip_financial_check

    def initialize(company, opts = {})
      @company = company
      @skip_financial_check = opts[:skip_financial_check]
    end

    def has_financial_transaction?
      company.primary_funding_account.present? && 
      company.primary_funding_account.funds_txns.present?
    end

    # some of these models have dependent: :destroy
    # and thats ok
    def reset!
      msg = "Cannot reset this account, because a gift card has been redeemed and approved"
      raise msg if has_financial_transaction? && !skip_financial_check
      Recognition.where(sender_company_id: company.id).destroy_all
      company.received_recognitions.map(&:destroy)
      RecognitionRecipient.where(sender_company_id: company.id).destroy_all
      PointActivity.where(company_id: company.id).destroy_all
      Tskz::CompletedTask.where(company_id: company.id).destroy_all
      Tskz::TaskSubmission.where(company_id: company.id).destroy_all
      ExternalActivity.where(company_id: company.id).destroy_all
      NominationVote.where(sender_company_id: company.id).destroy_all
      Nomination.where(recipient_company_id: company.id).destroy_all
      Redemption.where(company_id: company.id).destroy_all
      HallOfFame.reset_cache!(company)
      company.users.map(&:update_all_points!)
    end
  end
end
