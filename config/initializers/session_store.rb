# Be sure to restart your server when you modify this file.

# Recognize::Application.config.session_store :cookie_store, key: '_recognize_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
opts = {}
if Rails.configuration.host == "recognizeapp.com"
  opts =  {expire_after: 2.months, domain: :all}
else
  # NOTE: With the upgrade of rack from 2.0.7 to 2.2.3
  #       The tests are failing when the key is specified.
  #       Could theoretically turn this off just for tests,
  #       But do we need this anyway?
  #       I think this was an attempt to allow multiple sessions on different
  #       domains, otherwise, the cookies with collide.
  #       So, we'll turn off for now and maybe re-enable later if its
  #       an issue.
  # opts[:key] = "Recognize-#{Rails.configuration.host}-#{`echo $USER`.strip}"

  # opts[:domain] = Rails.configuration.host
end

# Force these for now
unless Rails.env.test?
  opts[:secure] = true
  opts[:same_site] = :none
end

Rails.application.config.session_store :active_record_store, **opts

# FIXME-RAILS6.1: This new way of setting same_site = "None"
#                 is not backwards compatible with versions before 6.1.
#                 So we still have to rely on the gem rails_same_site_cookie.
#                 After upgrading to >=6.1 remove the gem and
#                 uncomment the line that follows.
#                 Testing: check if the logout from inside an iframe
#                 (MS Teams, Sharepoint) is successful.

# Rails.application.config.action_dispatch.cookies_same_site_protection = :none

# Note: Until then we just make sure this is raised after
#       each rails upgrade to remind us to double check the behaviour.
#       Update the version number for every minor upgrade until 6.1.
#       After that you can test the scenario mentioned above and
#       can remove it.
raise "Double check session_store.rb for same_site implementation." unless Rails.version == "6.0.3.7"
