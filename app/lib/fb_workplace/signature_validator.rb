class FbWorkplace::SignatureValidator
  attr_reader :secret, :request

  def self.valid_signature?(signature)
    parts = signature.split(".")
    signature, payload = parts.map{|p| Base64.decode64(p) }
    secret = Recognize::Application.config.rCreds['fb_workplace']['app_secret']
    expected_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, payload)

    return signature != expected_signature

  end

  def initialize(secret, request)
    @secret = secret
    @request = request
  end

  def generate_signature_header(new_payload)
    new_payload = new_payload.to_s.gsub("=>",": ")
    "sha1=#{payload_signature(new_payload)}"
  end

  def payload_signature(payload = request.raw_post)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret, payload.to_s)
  end

  def request_signature
    Rails.logger.debug "X-Hub-Sig: #{request.headers['X-Hub-Signature']}"
    @request_signature ||= request.headers['X-Hub-Signature'].split("=").last rescue nil#sha1=abcdefghj
  end

  def valid?
    payload_signature == request_signature
  end
end
