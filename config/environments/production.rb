require_relative("../../app/lib/local_config")
require 'uglifier' if ENV['RAILS_DEPLOY_SCRIPT'].present?
Rails.application.configure do
  #CONFIG = YAML.load_file("#{Rails.root.to_s}/config/credentials.yml")[Rails.env]
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = Uglifier.new(harmony: true) if ENV['RAILS_DEPLOY_SCRIPT'].present?
  config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  config.hosts << ".recognizeapp.com"
  config.hosts << Net::HTTP.get(URI('http://169.254.169.254/latest/meta-data/local-ipv4')) rescue nil

  #elk setup

  # if ENV['elk_dns'].blank?
  #   puts "no value for ELK DNS - "
  # else
  #   config.lograge.enabled = true
  #   config.lograge.formatter = Lograge::Formatters::Logstash.new
  #   #elk_dns : env variable for classic load balanser dns value
  #   config.lograge.logger = LogStashLogger.new(type: :tcp, host: ENV['elk_dns'], port: 5000)
  # end

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "recognize_#{Rails.env}"
  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  config.action_mailer.raise_delivery_errors = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  config.before_configuration do
    if Recognize::Application.config.rCreds['aws'].has_key?('elasticache')
      endpoint = Recognize::Application.config.rCreds['aws']['elasticache']['endpoint']
      config.cache_store = :redis_store, "redis://#{endpoint}/prod/cache", { expires_in: 1.month }
    end
  end

  config.before_initialize do
    # config.action_controller.asset_host = "//#{Recognize::Application.config.rCreds['aws']['bucket']}.s3.amazonaws.com"
    config.action_controller.asset_host = "//#{Recognize::Application.config.rCreds['aws']['cloud_front']}"
    Recognize::Application.config.asset_host = config.action_controller.asset_host#make a shorter alias to this

    #point mailer assets to s3 so they can point to non-digest assets and not have to worry about caching
    config.action_mailer.asset_host = "http://#{Recognize::Application.config.rCreds['aws']['bucket']}.s3.amazonaws.com"
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  config.host = "recognizeapp.com"

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  config.action_mailer.delivery_method   = :smtp

  config.before_initialize do
    Recognize::Application.config.middleware.use ExceptionNotification::Rack,
      email: {
        :email_prefix => "[#{Recognize::Application.config.host}] ",
        :sender_address => "donotreply@recognizeapp.com",
        :exception_recipients => "errors@recognizeapp.com",
        :sections => %w(data request session backtrace environment),
        :background_sections => %w(data backtrace)

      }

    if Recognize::Application.config.rCreds['smtp_settings'].present? && Recognize::Application.config.rCreds['smtp_settings']['user_name'].present?
      smtp_config = Recognize::Application.config.rCreds['smtp_settings']
      config.action_mailer.smtp_settings = {
        :address              => smtp_config['address'],
        :port                 => smtp_config['port'] || 587,
        :user_name            => smtp_config['user_name'],
        :password             => smtp_config['password'],
        :authentication       => smtp_config['authentication'] || 'login',
        :enable_starttls_auto => true  }
    else
      config.action_mailer.smtp_settings = {
        :address              => "smtp.mandrillapp.com",
        :port                 => 587,
        :user_name            => Recognize::Application.config.rCreds['mandrill']['username'],
        :password             => Recognize::Application.config.rCreds['mandrill']['password'],
        :authentication       => 'login',
        :enable_starttls_auto => true  }
    end
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end
