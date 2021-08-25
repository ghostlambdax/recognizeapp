# encoding: utf-8
class BackupUploader < CarrierWave::Uploader::Base
  def store_dir
    "backups/db/"
  end
end
