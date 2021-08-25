Slack.configure do |config|
  if Recognize::Application.config.rCreds["slack"]
    config.token = Recognize::Application.config.rCreds["slack"]["incoming_token"]
  end
end
