source 'https://rubygems.org'
ruby "2.7.2"

gem 'rails', '6.0.3.7'
gem 'net-ssh'
gem 'rake', '< 14.0'
gem 'rack', '~> 2.2.3'

# rails 4 upgrade gems
gem 'rails-observers', '~> 0.1.5'
gem 'activerecord-session_store'

gem 'turbolinks', '~> 5.2.0'
gem 'nprogress-rails'
gem 'sitemap_generator'
gem 'netaddr'
gem 'responders'
gem "password_strength"

gem 'mysql2', '~> 0.5.2'
gem 'jquery-rails', '~> 4.3'
gem 'authlogic', '~> 6.0'
gem 'scrypt', '~> 3.0.6'
#use the below if you get an authlogic error about not being able to connect to the database.
#so enable line, run migrations or whatever you need to do, but then don't forget to change back!
#it should go away after migrating
#gem 'authlogic', :git => 'git://github.com/james2m/authlogic.git', :branch => 'fix-migrations'
# gem 'exception_notification', git: 'git://github.com/smartinez87/exception_notification.git'
gem 'exception_notification'
gem "active_attr"
gem 'rails-i18n'
gem 'declarative_authorization', github: 'ledermann/declarative_authorization' # todo: use self-hosted fork
gem 'fog-aws'
gem 'carrierwave', github: 'carrierwaveuploader/carrierwave'
gem "mini_magick"
gem 'bourbon'
gem 'domainatrix'
gem 'ios-checkboxes'
gem 'will_paginate', '~> 3.3.0'
gem "delayed_job_active_record", '4.1.4', require: 'delayed_job_active_record'
gem "delayed_job", require: 'delayed_job'
gem "delayed_job_web"

gem 'progress_job' #progress for delayed_job

gem 'translation'

# Downgraded from 2.7.0 to 2.6.0 ;See https://github.com/roo-rb/roo/issues/374.
gem "roo", "2.6.0" # provides interface to spreadsheets of several sorts
# xlsx generation - this is ok to roll back, just upgraded to get rid of deprecation warnings
gem "caxlsx"
gem "zip-zip" # need to get `axlsx` to work (https://github.com/randym/axlsx/issues/234)

gem 'omniauth'
gem 'omniauth-yammer'
gem "omniauth-google-oauth2"
# gem 'omniauth-microsoft_graph', path: "../omniauth-microsoft_graph"
gem 'omniauth-microsoft_graph', '~> 0.3.3'
gem "omniauth-rails_csrf_protection"

gem "recaptcha"

gem 'gdata_19', require: 'gdata'
gem 'yam', '2.6.0', github: 'collabital/yam', branch: 'v2.6.0', require: 'yammer'
gem 'whenever', require: false
gem 'redis'
gem 'ddtrace'

# this comes with ruby generally, but to get a modern version of it with old version of ruby, need explicit include
gem 'ipaddr', '~> 1.2'

gem 'stripe'

gem 'colorize'
gem 'unicorn'
gem 'rack-cors', :require => 'rack/cors'
gem 'hashie', '>= 3.2.0'
gem 'geocoder'
gem 'activerecord-import'
gem 'analytics-ruby', '2.2.5'
gem 'twilio-ruby'
gem 'rest-client', '~> 2.0.2'
gem 'httparty'
gem 'ruby-saml','~> 1.8.0'
gem 'bulk_insert'
gem 'gon'
gem 'jwt'
gem 'gibbon'
gem 'ffi'
gem 'oj'
gem 'draper'
gem 'active_record_union'
gem 'addressable'

#need access to factory in main block because we use it in a rake task
#that may need to be run on heroku and heroku doesn't install dev/test gems
gem 'factory_bot'
gem 'factory_bot_rails'

gem 'timecop' #make available to production env so we can run reminder simulations...

# Note: This gem's source was setup to a github repo three years ago. Beginning April 26, 2017, it was modified to use the default gem (without any source). Be cautious of any issues that arise after the aforementioned date.
# gem "jquery-fileupload-rails", github: "cipacda/jquery-fileupload-rails"
gem "jquery-fileupload-rails"

gem 'money-rails'
gem 'money-currencylayer-bank', git: 'git://github.com/usmanasif/money-currencylayer-bank', ref: '18955ad'
gem 'paper_trail', '~> 10.2'

gem 'paranoia'
gem 'daemons', github: 'thuehlinger/daemons'
gem 'hashids'
gem 'wisper'
# gem 'wisper-celluloid'
gem 'redis-rails'

# FIXME-RAILS6.1: remove this and set same_site with
# `action_dispatch.cookies_same_site_protection` config in
# initializers/session_store.rb
gem 'rails_same_site_cookie'

#need this in all :assets, :production so that we can run the asset:sync task in production
# gem 'asset_sync', git: "git://github.com/rumblelabs/asset_sync.git", ref: "fefd9ddfa1b609eb39f6003d91dc52acf405a3e4", groups: [:assets, :production]
# gem 'rack-mini-profiler', groups: [:development]
# gem 'ruby-prof', groups: [:development]
gem 'sanitize_email'
gem 'active_model_serializers', '~> 0.9.4'
gem 'slack-ruby-client'

gem 'closeio'

# Api
gem 'doorkeeper', '5.4.0'
gem 'grape', '1.3.0'
gem 'grape-route-helpers'
# gem 'grape-swagger', github: 'synth/grape-swagger', branch: 'hide-module-from-path'#path: '/Users/pete/work/grape-swagger'
gem 'grape-swagger'
gem 'grape-swagger-entity'
gem 'grape-swagger-ui'
gem 'grape-entity', '0.7.1'

# FIXME: The repo being sourced from is the official repo. The commit has the patch which upgrade grape's dependency to
#        include 1.3.0. When wine_bouncer > 1.0.4 is released in rubygems, use that instead!
#        For more: https://github.com/antek-drzewiecki/wine_bouncer/issues/80
gem 'wine_bouncer', :git => 'https://github.com/antek-drzewiecki/wine_bouncer', :ref => 'c82b88f73c7adc43a8e89ca73f7e18952ec30de4'

gem 'api-pagination'
gem 'redcarpet'
gem 'rouge'

# Down is a utility tool for streaming, flexible and safe downloading of remote files.
gem "down", "~> 5.2.1"
gem 'puma', '~> 5.3.1'

# Rack middleware for blocking & throttling abusive requests
gem 'rack-attack', '6.3.0'

# For CMS pages, we want to fully cache those pages
gem 'actionpack-page_caching'
gem 'mechanize', require: false
gem "json", ">= 2.3.0"

gem 'aws-sdk-ssm'
gem 'aws-sdk-ecs'
gem 'aws-sdk-ec2'
gem 'aws-sdk-autoscaling'
gem 'bigdecimal', '~> 2.0.0'
gem 'sprockets', '3.7.2'
gem 'sass'

# gems added for webhooks
gem 'liquid'
gem 'lockbox'

group :development, :test do
  gem 'listen'
  gem 'hirb'
  gem 'interactive_editor'
  gem 'rails-erd'
  gem 'phantomjs', '1.9.7.1'
  gem 'jasmine-rails'
  gem 'rspec', '~> 3.5'
  gem 'rspec-core', '~> 3.5'
  gem 'rspec-rails', '~> 4.0'
  gem 'launchy'
  gem 'capybara', '~> 3.31'
  gem 'capybara-screenshot'
  gem 'selenium-webdriver'
  gem 'database_cleaner', '~> 1.6'
  gem 'email_spec'
  gem 'awesome_print'
  gem 'spring'
  gem "spring-commands-rspec"
  gem 'i18n-tasks'
  gem 'faker'
  #For most systems:
  # gem 'libv8', '~> 3.11.8.12', :platforms => :ruby
  # gem 'therubyracer', '~> 0.11.3', :require => 'v8', :platforms => :ruby

  #Possibly needed for some Mountain Lion Systems - "darwin12.2.0"
  # gem 'libv8', '~> 3.11.8'
  # gem 'therubyracer', '0.11.0beta5'

  gem 'simplecov', require: false
  gem 'memory_test_fix'
  gem 'bullet'
  gem 'brakeman', require: false
  gem 'headless'
  # gem 'psych', '~> 1.3.4' # if problems with psych, use this version
  gem 'psych', '~> 2.2.0'
  gem 'typhoeus'

  gem 'rack_session_access'
  gem 'knapsack_pro'
  # gem 'docker-sync', '~> 0.5.9'
  gem 'parallel_tests'

  gem 'rubyzip'

  gem 'pry'
  gem 'pry-remote'
  gem 'pry-rails'
  gem 'byebug'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request', '~> 0.7.0'
  gem 'test-unit'
  gem 'sshkit'
  gem 'rack-mini-profiler'
  gem 'flamegraph'
  gem 'fast_stack'
  gem 'web-console'
  gem 'rubocop', '~> 1.10.0', require: false
  gem 'rubocop-rails'
  gem 'parser', '~> 3.0.0.0'
  gem 'solargraph'
  gem 'octokit'
  gem "attr_masker", github: "riboseinc/attr_masker"
end

group :production do

end

group :test do
  gem "webmock"
  gem "vcr"
  gem 'rails-controller-testing'
  gem 'thor', '~> 1.1.0'
  gem 'rspec-retry'
  gem 'wisper-rspec', require: false
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', '~> 6.0'
  gem 'uglifier'
end

group :assets, :development, :test do
  # gem 'therubyracer'
  gem "autoprefixer-rails"
end

group :build do
  gem 'cleanup_vendor'
end
