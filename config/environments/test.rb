require 'active_support/core_ext/numeric/bytes'
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  config.allow_concurrency = false

  # https://github.com/rails/sprockets-rails/issues/352 (also in development.rb)
  config.assets.check_precompiled_asset = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=3600'
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Needed for _url generation via named routes
  # the default config.host set later in this file is overridden in local.yml / local.yml.travis
  if Recognize::Application.config.respond_to?(:host)
    config.action_mailer.default_url_options = {
      host: Recognize::Application.config.host
    }
  else
    config.action_mailer.default_url_options = {
      host:  "http://l.recognizeapp.com",
      port: 50000
    }
  end

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  config.host = "localhost:3000"
  config.hosts << "www.example.com"
  config.hosts << "example.com"
  config.hosts << "127.0.0.1"
  config.hosts << "recognize-sales.youcanbook.me"
  config.hosts << "creativecommons.org"
  config.serve_static_assets = true
  # config.asset_host = "//"+config.host

  #https://github.com/rails/sprockets-rails/issues/352
  config.assets.check_precompiled_asset = false

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  # config.logger = Logger.new(config.paths["log"].first, 1, 104857600)
  # config.log_level = :warn
  # config.cache_store = :null_store

  if ENV['TEST_ENV_NUMBER']
    assets_cache_path = Rails.root.join("tmp/cache/assets/paralleltests#{ENV['TEST_ENV_NUMBER']}")
    config.assets.cache = Sprockets::Cache::FileStore.new(assets_cache_path)
    config.cache_store = :file_store, Rails.root.join("tmp", "cache", "paralleltests#{ENV['TEST_ENV_NUMBER']}")
  else
    config.cache_store = :memory_store, { size: 256.megabytes }
  end

  config.middleware.use RackSessionAccess::Middleware

  config.assets.configure do |env|
    if ENV['ASSETS_IN_MEMORY']
      env.cache = ActiveSupport::Cache.lookup_store(:memory_store)
    end
  end

  config.assets.digest = false

  if ENV['PRECOMPILE_TEST_ASSETS']
    puts "Precompiling assets for tests"
    config.assets.prefix = "/capybara_test_assets"
    config.assets.enabled = false
    config.assets.cache_store = :null_store
    config.sass.cache = false
    # config.assets.compile = false
  end

  # added the asset compilation for the base theme of the recognizeapp
  config.assets.precompile += %w( themes/recognizeapp_com.css )
end
