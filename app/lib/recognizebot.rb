class Recognizebot
  attr_reader :opts, :client

  def self.say(opts)
    new(opts).say_it
  end

  def initialize(opts)
    @opts = opts
    @client = get_client
  end

  def get_client
    if Rails.env.test?
      MockSlackClient.new
    else
      Slack::Web::Client.new
    end
  end

  def say_it
    options = {}
    options[:channel] = "#test"
    options[:username] = "recognizebot"
    options[:icon_url] =  "https://recognizeapp.com/assets/chrome/logo_48x48.png"
    options.merge!(opts)
    if slack_credentials_present?
      client.chat_postMessage(options)
    else
      Rails.logger.warn "Slack has not been configured! Please add tokens to credentials.yml"
    end
  end

  private
  def slack_credentials_present?
    !!(Recognize::Application.config.rCreds["slack"]["incoming_token"] rescue nil)
  end

  class MockSlackClient
    def chat_postMessage(*args)
      Rails.logger.debug "Called MockSlackClient with #{args}"
    end
  end
end
