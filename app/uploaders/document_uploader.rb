# frozen_string_literal: true

class DocumentUploader < AttachmentUploader
  # Note: Although the intended way of saving unsanitized original filename (as suggested by the wiki: see
  # https://github.com/carrierwaveuploader/carrierwave/wiki/How-to:-Create-random-and-unique-filenames-for-all-versioned-files#saving-the-original-filename)
  # is to tap in `before :cache` hook. However, despite what the wiki says, there is a bug that doesn't allow it (see https://github.com/carrierwaveuploader/carrierwave/issues/1835).
  # Therefore, setting of `original_filename` is being done by overriding the `Uploader::Cache#cache!`.
  def cache!(file)
    save_original_filename(file)
    super
  end

  def save_original_filename(file)
    model.original_filename ||= file.original_filename if file.respond_to?(:original_filename)
  end

  def filename
    return if original_filename.blank?

    extension = File.extname(original_filename)
    filename_without_extension = original_filename.chomp(extension)
    "#{filename_without_extension}_#{secure_token}#{extension}"
  end

  # Method override!
  #
  # Datatable export for collections of records that are huge can result in documents whose file size can be greater
  # than 5 megabytes (which is the max file size allowed by the parent class - AttachmentUploader). Therefore, the
  # size_range has been increased for `Documents`.
  def size_range
    #Range is 1 byte to 100 megabyte.
    1..100.megabytes
  end

  def extension_allowlist
    %w[csv doc docx jpeg jpg pdf png xls xlsx]
  end

  protected

  def secure_token
    @secure_token ||= SecureRandom.hex(8)
  end

end
