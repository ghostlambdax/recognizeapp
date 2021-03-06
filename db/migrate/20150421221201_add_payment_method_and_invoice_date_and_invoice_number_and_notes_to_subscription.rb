class AddPaymentMethodAndInvoiceDateAndInvoiceNumberAndNotesToSubscription < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :payment_method, :string
    add_column :subscriptions, :invoice_date, :datetime
    add_column :subscriptions, :invoice_number, :integer
    add_column :subscriptions, :notes, :text
  end
end
