get '/auth/failure', to: 'authentications#failure', :as => :auth_failure
get '/auth/:provider', to: 'authentications#new', :as => :auth_interstitial
post '/auth/:provider', to: 'authentications#create', :as => :remote_auth
get '/auth/:provider/callback', to: 'authentications#create'
get '/auth/:provider/setup', :to => 'authentications#setup'
