class ChangeInvoiceDateColumnOnSubscriptions < ActiveRecord::Migration[4.2]
  def change
    rename_column :subscriptions, :invoice_date, :billing_start_date
  end
end
