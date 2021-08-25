class CreateRecognizeAdminFundingAccount < ActiveRecord::Migration[4.2]
  def up
    company = Company.find(1) rescue nil
    if company
      admin_acct = company.funds_accounts.build(recognize_admin: true)
      admin_acct.save!
    end
  end
end
