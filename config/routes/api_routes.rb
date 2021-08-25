get "/api/v1/auth_status", to: redirect("/api/auth_status")
get '/api/auth_status', to: 'authentications#auth_status' # purposefully not versioned or in a versioned namespace,
mount Api::Base => '/api'
