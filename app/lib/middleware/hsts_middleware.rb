# Most of the code here were extracted from https://github.com/rails/rails/blob/c4d3e202e10ae627b3b9c34498afb45450652421/actionpack/lib/action_dispatch/middleware/ssl.rb
class Middleware::HstsMiddleware
  # Default to 180 days, the low end for https://www.ssllabs.com/ssltest/
  # and greater than the 18-week requirement for browser preload lists.
  HSTS_EXPIRES_IN = 15552000

  def self.default_hsts_header_opts
    { expires: HSTS_EXPIRES_IN, subdomains: true, preload: false }
  end

  def initialize(app)
    @app = app
    @hsts_header = build_hsts_header
  end

  def call(env)
    @app.call(env).tap do |status, headers, response|
      set_hsts_headers! headers if Rails.env.production?
    end
  end

  private

  def set_hsts_headers!(headers)
    headers['Strict-Transport-Security'.freeze] ||= @hsts_header
  end

  # http://tools.ietf.org/html/rfc6797#section-6.1
  def build_hsts_header(hsts = self.class.default_hsts_header_opts)
   value = "max-age=#{hsts[:expires].to_i}"
   value << "; includeSubDomains" if hsts[:subdomains]
   value << "; preload" if hsts[:preload]
   value
  end
end
