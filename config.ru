# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

DelayedJobWeb.use Rack::Auth::Basic do |username, password|
  ActiveSupport::SecurityUtils.variable_size_secure_compare(ENV['DJ_ADMIN_USERNAME'], username) &&
    ActiveSupport::SecurityUtils.variable_size_secure_compare(ENV['DJ_ADMIN_PASSWORD'], password)
end

run Recognize::Application
