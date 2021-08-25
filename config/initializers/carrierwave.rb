require 'carrierwave/storage/fog'

if Rails.env.production? && Recognize::Application.config.rCreds.dig('aws', 'aws_access_key_id').present?
  CarrierWave.configure do |config|
    config.fog_credentials = {
      :provider               => 'AWS',
      :aws_access_key_id      => Recognize::Application.config.rCreds.dig('aws', 'aws_access_key_id'),
      :aws_secret_access_key  => Recognize::Application.config.rCreds.dig('aws', 'aws_secret_access_key'),
      :region                 => Recognize::Application.config.rCreds.dig('aws', 'region')
    }
    config.fog_directory  = Recognize::Application.config.rCreds['aws']['bucket']
    config.fog_public     = true
    config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}
    config.storage = :fog
  end
else
  CarrierWave.configure do |config|
    config.storage = :file
    config.asset_host = ActionController::Base.asset_host
  end
end

module CarrierWave
  module MiniMagick
    def quality(percentage)
      manipulate! do |img|
        img.quality(percentage.to_s)
        img = yield(img) if block_given?
        img
      end
    end
  end
end
