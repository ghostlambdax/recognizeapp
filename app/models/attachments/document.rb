# frozen_string_literal: true

class Document < Attachment
  mount_uploader :file, DocumentUploader

  belongs_to :uploader, class_name: "User", foreign_key: :uploader_id, inverse_of: :documents_uploaded, optional: true
  belongs_to :requester, class_name: "User", foreign_key: :requester_id, inverse_of: :documents_requested, optional: true

  before_validation :nilify_blank_description
  validates :file, presence: true, if: ->(document) { document.errors[:file].blank? }

  scope :accessible_by_manager_admin, ->(user) do
    where(company_id: user.company_id).where(requester_id: user.id).or(where(uploader_id: user.id)).where.not(type: "InvoiceDocument")
  end

  scope :uploads, -> { where(requester_id: nil) } # uploaded by user
  scope :downloads, -> { where.not(requester_id: nil) } # created by system as requested from user to be ready for download
  scope :not_invoice, -> { where.not(type: "InvoiceDocument") }

  def requested?
    requester_id.present?
  end

  # The `upload_date` is really the `created_at`, because the record is created with file attached to it.
  def uploaded_at
    created_at
  end

  private

  def nilify_blank_description
    self.description = nil if self.description.blank?
  end
end
