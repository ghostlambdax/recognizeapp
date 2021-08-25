# frozen_string_literal: true

class InvoiceDocument < Document
  mount_uploader :file, InvoiceDocumentUploader

  scope :unpaid, -> { where(date_paid: nil) }
  scope :upcoming, -> { where('due_date <= ?', 1.month.from_now.to_date)}


end
