# encoding: utf-8

class EndUserGuideUploader < AttachmentUploader

  # def default_url
  #   asset_path("icons/user-default.png")
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:


  # Add a white list of extensions which are allowed to be uploaded.
  def extension_allowlist
    ["pdf"]
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
