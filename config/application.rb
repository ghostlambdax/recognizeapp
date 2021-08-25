require_relative('boot')

require 'rails/all'

# needed this in production docker env for some reason
# https://github.com/rswag/rswag/issues/12
require 'sprockets/railtie'

require_relative('../app/lib/local_config')
require_relative('../lib/credentials')
require_relative('../app/models/points/calculator') #hack, i don't know why rails can't figure this out...
require_relative('../app/lib/microsoft_graph_client') #need this, otherwise loading companies and deserializing sync_groups will fail

require_relative('../app/lib/middleware/workplace_middleware') #need this, otherwise loading companies and deserializing sync_groups will fail
require_relative('../app/lib/middleware/autocompleter')
require_relative('../app/lib/middleware/cors_assets')
require_relative('../app/lib/middleware/hsts_middleware')

# Bundler.require(:default, Rails.env)
Bundler.require(*Rails.groups)

module Recognize
  class Application < Rails::Application
    config.load_defaults 6.0

    SKIP_CONTENT_FOR = "SKIP_CONTENT_FOR" # must be string otherwise, rails encodes it during view output

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += Dir[ Rails.root.join('app', 'models', "concerns") ]
    config.autoload_paths += Dir[ Rails.root.join('app', 'forms') ]
    config.autoload_paths += Dir[ Rails.root.join('app', 'assets', 'fonts') ]

    config.autoload_paths += %W(#{config.root}/app/models/attachments)
    config.autoload_paths += %W(#{config.root}/app/services)
    config.autoload_paths += %W(#{config.root}/app/listeners)
    config.autoload_paths += %W(#{config.root}/app/controllers/concerns)
    config.autoload_paths += %W(#{config.root}/app/middleware)
    config.autoload_paths += %W(#{config.root}/app/controllers/interfaces)
    config.paths.add File.join('app', 'controllers', 'interfaces'), glob: File.join('**', '*.rb')
    config.paths.add File.join('app', 'controllers', 'interfaces'), glob: File.join('**/**/', '*.rb')
    config.paths.add File.join('app', 'controllers', 'interfaces'), glob: File.join('**/**/**/', '*.rb')
    config.eager_load_paths += %W(#{config.root}/app/controllers/interfaces)

    config.autoload_paths << Rails.root.join('config/routes')

    config.active_record.cache_versioning = false

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Turn off observers during rake tasks because it may happen that we are migrating
    # from scratch and tables don't exist that may get loaded.  Eg, badge's are loaded in
    # a scope in Recognition class which is autoloaded for recognition observer
    #
    # WARNING: this is potentially dangerous if we write a rake task that depends on the
    #          observers for certain functionality...
    #
    unless File.basename($0) == 'rake' and (ARGV[0] == "db:migrate" || ARGV[0] == "recognize:init")
      config.active_record.observers = :recognition_observer, :user_observer, :"Tskz::CompletedTaskObserver", :"Points::ChangeObserver"
    end

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Pacific Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    # # rails will fallback to config.i18n.default_locale translation
    # config.i18n.enforce_available_locales = true
    #
    # config.i18n.fallbacks = true

    # rails will fallback to en, no matter what is set as config.i18n.default_locale
    config.i18n.fallbacks = [:en]

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    config.action_controller.default_url_options = { :trailing_slash => true }

    config.active_job.queue_adapter = :delayed_job

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enable the asset pipeline
    config.assets.enabled = true

    config.assets.initialize_on_precompile = false
    config.assets.expire_after 2.weeks

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # via https://github.com/sstephenson/sprockets/issues/347#issuecomment-25543201
    # We don't want the default of everything that isn't js or css, because it pulls too many things in
    config.assets.precompile.shift

    # Explicitly register the extensions we are interested in compiling
    config.assets.precompile.push(Proc.new do |path|
      File.extname(path).in? [
        '.html', '.erb', '.haml',                 # Templates
        '.png',  '.gif', '.jpg', '.jpeg', '.svg', '.apng', # Images
        '.eot',  '.otf', '.svc', '.woff', '.ttf', # Fonts
        '.pdf',                                     # Pdfs
        '.mp4'                                     #video
      ]
    end)

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w(browsers/ie9.css browsers/ie8.css browsers/ie.css browsers/unsupported.css marketing.css shared.css
                                 pages/marketing-pages.css marketing.js 3p/shims/selectivizr-min.js 3p/shims/html5.js 3p/excanvas.compiled.js
                                 pages/admin_index/queue.js 3p/zclip/jquery.zclip.min.js 3p/zclip/ZeroClipboard.swf
                                 pages/home/payment-confirmation.css pages/home/paymentConfirmation.js lib/flipflip.js 3p/hopscotch.js 3p/hopscotch.css notice_tour.js
                                 3p/shims/backgroundSize.js 3p/handlebars.js lib/browsers/ie.js lib/instantRecognition.js 3p/raphael/raphael.js 3p/raphael/pie.js
                                 extension.js extension.css 3p/xdomain.js
                                 extension/yammer/templates/htaccess.txt
                                 datatables.css datatables.js 3p/bootstrap-datepicker.js 3p/bootstrap-datepicker.css
                                 3p/es6-promise/promise.js 3p/autotrack.js
                                 panel.css panel.js outlook-load.js ms_teams.js ms_teams.css
                                 3p/feather.js.map chrome/logo-mark.png 3p/jquery.royalslider.min.js 3p/sweet-alert.js 3p/konva.js
                                 )

    config.middleware.insert_before 0, Middleware::WorkplaceMiddleware
    config.middleware.insert_before 0, Middleware::Autocompleter
    config.middleware.insert_before 0, Middleware::HstsMiddleware
    config.middleware.use Middleware::CorsAssets

    # For rails applications with versions >= 5.1 it is used by default in the gem's latest version (6.3.0)
    # While upgrading also check the position of the rack-attack in middlewares' stack
    # A TODO due to limited domain knowledge
    # raise "Check if rack attack is already included by default" if Rails.version >= "5.1"
    config.middleware.insert_before 0, Rack::Attack

    config.before_configuration do
      LocalConfig.apply_local_configs(config)
      Credentials.load_credentials(config)
    end

    config.after_initialize do
      #the local config needs to be after initialize b/c
      #it needs to overwrite any settings in env specific files
      #but when it goes in an after initialize block it misses setting some
      #settings that invoke functionality like force_ssl which will be missed
      #if this is an after_initialize block
      #what if we put it both in a before block and an after block...
      LocalConfig.apply_local_configs(config)
      ActionMailer::Base.default_url_options = {:host => Recognize::Application.config.host}
      OmniAuth.config.full_host = "https://"+Rails.application.config.host
      Rack::Attack.throttled_response_retry_after_header = true
    end

    config.api_only = false # need to avoid: 'You must provide a session to use OmniAuth.'

    config.middleware.insert 0, Rack::Cors do
      allow do
        origins 'localhost:3000',
          '192.168.1.12:3000',
          '127.0.0.1:3000',
          'chrome-extension://aenbpknnabhohbnngaidegdcldbbjccm',
          'https://www.yammer.com'
        resource '*',
          methods: [:get, :post, :put, :delete, :options]
      end
    end

    Dir.mkdir("log") unless File.exists?("log") # try to work around deploy issue
    config.yammer_logger = Logger.new("log/yammer.log")

  end
end
