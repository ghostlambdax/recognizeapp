class FbWorkplace::AccessToken
  ACCESS_TOKEN_ENDPOINT = "https://graph.facebook.com/v2.9/oauth/access_token"

  attr_reader :code

  def initialize(code)
    @code = code
    @valid = false
  end

  def to_s
    token
  end

  def valid?
    token && @valid
  end

  def token
    @token ||= begin
      if client_id.present? && client_secret.present?
        token = RestClient.get(ACCESS_TOKEN_ENDPOINT, {params: params})
        parsed_token = JSON.parse(token)['access_token'] rescue nil
        @valid = parsed_token.kind_of?(String)
        parsed_token || -1 #memo-ize to something non-nil on failure to make prevent multiple calls
      else
        nil
      end
    rescue RestClient::ExceptionWithResponse => e
      FbWorkplace::Logger.log(e)
      JSON.parse(e.response) rescue e.response
    end
  end

  def params
    {
      client_id: client_id,
      redirect_uri: redirect_uri,
      client_secret: client_secret,
      code: code
    }
  end

  private
  def client_id
    Recognize::Application.config.rCreds['fb_workplace']['app_id'] rescue nil
  end

  def client_secret
    Recognize::Application.config.rCreds['fb_workplace']['app_secret'] rescue nil
  end

  def redirect_uri
    Rails.application.routes.url_helpers.workplace_callback_url(host: Rails.application.config.host, protocol: "https")
  end
end
