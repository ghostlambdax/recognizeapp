# Rails.application.config.after_initialize do
#   puts "omniauth after init"
#   Rails.application.config.middleware.use OmniAuth::Builder do
#     provider :yammer, 'A6ItevIO7XS1rxIKzdPCw', 'QXoUPFvY5Pzxuwzq7VZ5JVLrJLU6S7oCjb979ENt0Y', {client_options: {ssl: {ca_file: Rails.configuration.local_config['ca_cert_file']}}}
#   end
# end
Rails.application.config.middleware.use OmniAuth::Builder do

  # if !Rails.env.production? && !File.exists?(Rails.configuration.local_config['ca_cert_file'])
  #   #wget http://www.cacert.org/certs/root.crt
  #   #not having this set cause some really strange things to happen switching from yammer to ms graph
  #   raise "#{Rails.configuration.local_config['ca_cert_file']} does not exist. Fix local.yml to point to a valid certificate"
  # end

  if Rails.env.test?
    provider :developer
  end

  if Recognize::Application.config.rCreds['yammer'].present?
    provider :yammer,
      Recognize::Application.config.rCreds['yammer']['client_id'],
      Recognize::Application.config.rCreds['yammer']['client_secret'],
      {
        provider_ignores_state: true,
        client_options: {
          ssl: {ca_file: Rails.configuration.local_config['ca_cert_file']},
          token_method: :get,
          token_url: "https://www.yammer.com/oauth2/access_token.json"
        }
      }
  end

  if Recognize::Application.config.rCreds['google'].present?
    provider :google_oauth2,
      Recognize::Application.config.rCreds['google']['client_id'],
      Recognize::Application.config.rCreds['google']['secret'],
      {
       scope: "userinfo.email,userinfo.profile,https://www.googleapis.com/auth/contacts.readonly",
       access_type: 'online',
       approval_prompt: '',
       client_options: {ssl: {ca_file: Rails.configuration.local_config['ca_cert_file']}}
    }
  end

  if Recognize::Application.config.rCreds['o365'].present?
    provider :microsoft_graph,
      Recognize::Application.config.rCreds['o365']['client_id'],
      Recognize::Application.config.rCreds['o365']['secret'],
      {
       setup: true,
       # client_options: {
       #    token_url:     'common/oauth2/v2.0/token',
       #    authorize_url: 'common/oauth2/v2.0/authorize'
       #  },
       # scope: "https://graph.microsoft.com/profile https://graph.microsoft.com/email https://graph.microsoft.com/User.Read https://graph.microsoft.com/User.ReadBasic.All"
      }
  end
end

# OmniAuth.config.on_failure = AuthenticationsController.action(:oauth_failure)
# Wrap this in a proc b/c in development env, the reloading of classes fudges with this
# due to middleware calling this presumably before class reloading middleware
OmniAuth.config.on_failure = Proc.new { |env|
  AuthenticationsController.action(:oauth_failure).call(env)
}

# this needs to be loaded after local config, so see application.rb
# OmniAuth.config.full_host = Rails.application.config.host
