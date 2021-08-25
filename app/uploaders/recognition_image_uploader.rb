# frozen_string_literal: true

class RecognitionImageUploader < ImageAttachmentUploader
  # store single version only
  process resize_to_limit: [640, 480]

  def initialize(company)
    @company_id = company.id
    super()
  end

  def extension_allowlist
    %w[jpg jpeg gif png ico]
  end

  # Overrides parent method in AttachmentUploader to remove model / mount info and adds company scoping instead
  # as neither is this uploader mounted to a model column, nor is the model created yet during this upload
  def store_dir
    "uploads/#{Rails.env}/recognitions/#{@company_id}"
  end

  # The filename is not being cached in model (unlike the suggestion in Carrierwave wiki) as this uploader is not mounted
  # Also, the @filename instance var should not be used for memoization here, as it already exists beforehand
  def filename
    @custom_filename ||= "#{SecureRandom.uuid}.#{file.extension}" if original_filename.present?
  end
end
