# Keys are managed: https://www.google.com/recaptcha/admin
Recaptcha.configure do |config|
  if Rails.env.test?
    # These test keys are taken from here:
    # https://developers.google.com/recaptcha/docs/faq#id-like-to-run-automated-tests-with-recaptcha-what-should-i-do
    config.site_key = "6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI"
    config.secret_key = "6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe"
  else
    config.site_key = Recognize::Application.config.rCreds.dig("recaptcha", "site_key")
    config.secret_key = Recognize::Application.config.rCreds.dig("recaptcha", "secret_key")
    # Uncomment the following line if you are using a proxy server:
    # config.proxy = 'http://myproxy.com.au:8080'
  end
end
