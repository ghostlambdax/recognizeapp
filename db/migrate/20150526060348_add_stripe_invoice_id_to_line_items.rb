class AddStripeInvoiceIdToLineItems < ActiveRecord::Migration[4.2]
  def change
    add_column :line_items, :stripe_invoice_id, :string
  end
end
