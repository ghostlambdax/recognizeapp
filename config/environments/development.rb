require_relative('../../app/lib/middleware/dev_image_ignorer')

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    puts "********* Turning on caching **********"
    config.action_controller.perform_caching = true

    config.cache_store = :redis_store, "redis://localhost:6379/dev/cache", { expires_in: 1.month }
    config.public_file_server.headers = {
      'Cache-Control' => 'public, max-age=172800'
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # For mailcatcher
  if Credentials.credentials_present?("smtp_settings", %w[address user_name password])
    smtp_config = Recognize::Application.config.rCreds['smtp_settings']
    config.action_mailer.smtp_settings = {
      :address              => smtp_config['address'],
      :port                 => smtp_config['port'] || 587,
      :user_name            => smtp_config['user_name'],
      :password             => smtp_config['password'],
      :authentication       => smtp_config['authentication'] || 'login',
      :enable_starttls_auto => true  }
  else
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = { :address => "localhost", :port => 1025 }
  end

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  # config.assets.quiet = true

  config.assets.precompile += %w(themes/*_*.css)

  #https://github.com/rails/sprockets-rails/issues/352
  config.assets.check_precompiled_asset = false

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.host = "localhost:3000"

  # Allowed hosts for dev env
  config.hosts << "l.recognizeapp.com"
  config.hosts << ".ngrok.io"

  # If using ngrok, you won't get webconsole unless you whitelist your ip address
  # Add to local.yml: 
  #    webconsole_ip: <%= `curl -s http://checkip.dyndns.org/ | sed 's/[a-zA-Z<>/ :]//g' |head -n1` %>
  config.web_console.permissions = Rails.configuration.local_config['webconsole_ip'] if Rails.configuration.local_config.key?('webconsole_ip')

  # config.asset_host = "//"+config.host

  # config.logger = Logger.new(config.paths["log"].first, 1, 104857600)
  logger = ActiveSupport::Logger.new(config.paths["log"].first, 1, 104857600)
  logger.formatter = config.log_formatter
  config.logger = ActiveSupport::TaggedLogging.new(logger)

  config.middleware.insert_before 0, Middleware::DevImageIgnorer

  config.before_initialize do

    Recognize::Application.config.middleware.use ExceptionNotification::Rack,
      email: {
        :email_prefix => "[#{Recognize::Application.config.host}] ",
        :sender_address => "donotreply@recognizeapp.com",
        :exception_recipients => "devexceptions@recognizeapp.com", # doesnt matter as it goes to mailcatcher...
        :sections => %w(data request session backtrace environment),
        :background_sections => %w(data backtrace)
      }

    # config.action_mailer.smtp_settings = {
    #   :address              => "smtp.mandrillapp.com",
    #   :port                 => 587,
    #   :user_name            => Recognize::Application.config.rCreds['mandrill']['username'],
    #   :password             => Recognize::Application.config.rCreds['mandrill']['password'],
    #   :authentication       => 'login',
    #   :domain               => Recognize::Application.config.host,
    #   :enable_starttls_auto => true  }
  end

  config.after_initialize do
    #enable Bullet for n+1 query checking
    Bullet.enable = true
    Bullet.add_footer = true
    Bullet.alert = false
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
  end

  BetterErrors.editor = :sublime
end
