class FbWorkplace::Webhook::Proxy
  attr_reader :proxy_params, :request, :secret

  def initialize(proxy_params, request, secret)
    @proxy_params = proxy_params
    @request = request
    @secret = secret
  end

  def headers
    {"X-Hub-Signature" => request_signature, content_type: :json, accept: :json}
  end

  def payload
    # not sure why :workplace is in the params, its been entered in there somehow
    # and is a duplicate of the :entry param
    request.params.except(:controller, :action, :workplace)
  end

  def request_signature
    sig_validator = FbWorkplace::SignatureValidator.new(secret, request)
    sig_validator.generate_signature_header(payload)
  end

  def send!
    response = RestClient.post(proxy_url, payload.to_json, headers)
    # Rails.logger.debug "Response: #{response}"
    return response
  end

  private
  def proxy_host
    @proxy_params[:host]
  end

  def proxy_path
    @proxy_params[:path]
  end

  def query_string
    @proxy_params[:query_string]
  end

  def proxy_url
    "https://#{proxy_host}#{proxy_path}?#{query_string}"
  end
end