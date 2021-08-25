class ChangeInvoiceDocumentPaidFlagToDate < ActiveRecord::Migration[5.0]
  def change
    remove_column :attachments, :is_paid
    add_column :attachments, :date_paid, :date
  end
end
