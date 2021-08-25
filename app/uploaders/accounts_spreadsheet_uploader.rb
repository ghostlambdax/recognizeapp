# encoding: utf-8

class AccountsSpreadsheetUploader < AttachmentUploader
  process :override_content_type

  # Add a white list of extensions which are allowed to be uploaded.
  def extension_allowlist
    ["xlsx", "csv"]
  end

  def override_content_type
    if File.extname(file.file).delete('.').to_sym == :xlsx
      file.content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    end
  end
end
