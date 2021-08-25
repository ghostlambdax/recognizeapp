class AddCompanyToFundsAccount < ActiveRecord::Migration[4.2]
  def change
    add_reference :funds_accounts, :company, index: true
  end
end
