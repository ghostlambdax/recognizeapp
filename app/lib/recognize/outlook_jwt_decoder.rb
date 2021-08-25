module Recognize
  class OutlookJwtDecoder
    attr_reader :encrypted_token, :valid, :header, :payload, :decoded_token, :errors, :metadata, :app_context

    def initialize(encrypted_token)
      @encrypted_token = encrypted_token
      @valid = true
      @errors = []
    end

    def algorithm
      header["alg"]
    end

    def app_context
      @app_context ||= JSON.parse(payload["appctx"]) rescue {}
    end

    def audience
      @audience ||= payload["aud"]
    end

    def certificate
      @certificate ||= begin
        OpenSSL::X509::Certificate.new(Base64.decode64(x509_b64))
      rescue => e
        invalidate!("invalid_x509")
        nil
      end
    end

    def exchange_id
      app_context['msexchuid']
    end

    def expiration
      @expiration ||= Time.at(payload["exp"]) rescue nil
    end

    def invalidate!(msg)
      @valid = false
      @errors << msg
    end

    def metadata_url
      @metadata_url ||= app_context["amurl"] rescue nil
    end

    def public_key
      @public_key ||= certificate.public_key rescue nil
    end

    def unique_id
      @unique_id ||= begin
        id = "#{metadata_url}#{exchange_id}"
        md5 = Digest::MD5.new
        md5.update(id)
        md5.hexdigest
      end
    end

    def validate
      extract
      validate_format if valid?
      retrieve_metadata if valid?
      validate_signature if valid?
    end

    def valid?
      @valid
    end

    def x509_b64
      metadata["keys"].first["keyvalue"]["value"] rescue nil
    end

    private
    def extract
      begin
        parts = JWT.decode(encrypted_token, nil, false)
        @header = parts[1]
        @payload = parts[0]
      rescue => e
        invalidate!(e.message)
      ensure
        @header ||= {}
        @payload ||= {}
      end
    end

    def retrieve_metadata
      @metadata ||= HTTParty.get(metadata_url) rescue nil
    end

    def validate_audience
      valid_audiences = Recognize::Application.config.valid_hosts
      invalidate!("invalid_audience") unless valid_audiences.any?{|a| audience.include?(a) }
    end

    def validate_format
      validate_not_expired
      validate_audience
      validate_metadata_url
    end

    def validate_metadata_url
      if metadata_url.blank?
        invalidate!("missing_metadata_url") 
      else
        uri = URI.parse(metadata_url)
        if uri.host != "outlook.office365.com"
          invalidate!("invalid_metadata_url: #{uri.host}")
        end
      end
    end

    def validate_not_expired
      invalidate!("expired") if expiration <= Time.now
    end

    def validate_signature
      begin
        @decoded_token = JWT.decode(encrypted_token, public_key, true, {algorithm: algorithm})
      rescue JWT::VerificationError
        invalidate!("invalid_token")
      rescue => e
        invalidate!(e.message)
      end
    end

  end
end
