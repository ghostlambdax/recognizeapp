get "/users", to: "users#index", as: "users"
resources :users, path: "", path_names: {new: "users/new"}, except:[:index, :create] do
  collection do
    get :invite
    get :get_suggested_yammer_users
    get :get_relevant_yammer_coworkers
    patch :send_invitations      
    patch :invite_from_yammer
    post :update_favorite_teams
    get :counts
  end
  member do
    patch :promote_to_admin
    patch :demote_from_admin
    patch :promote_to_executive
    patch :demote_from_executive
    put :hide_welcome
    put :has_read_new_feature
    put :activate
    patch :upload_avatar
    patch :update_slug
    patch :revoke_oauth_token
    get :received_recognitions
    get :sent_recognitions
    get :direct_reports
    get :managed_users
    get :nominations
    post :manager
    post :device_token
  end

  # USER RECOGNITION ROUTES
  resources :recognitions, only: [] do
    collection do
      get :sent
      get :received
    end
  end

  resource :company_roles, only: [:create, :destroy], controller: :user_company_roles
  resource :teams, only: [:create, :destroy], controller: :user_teams
  resources :device_tokens, only: [:create, :destroy] # /users/:id/device_tokens user_device_tokens_path
  resources :points, only: [:index], controller: :user_points
end
