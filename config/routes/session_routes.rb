get '/ping', to: 'user_sessions#ping'
get '/login', to: 'user_sessions#new'
# overrides the user_sessions path helper to point to this path
post '/login', to: 'user_sessions#create', as: :user_sessions
get '/logout', to: 'user_sessions#destroy', :as => :logout
resources :user_sessions