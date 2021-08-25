resources :subscriptions
get '/upgrade', to: "subscriptions#new", as: :upgrade  
get '/upgrade/(:code)', to: "subscriptions#new"