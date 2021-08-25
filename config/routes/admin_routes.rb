get '/admin', to: 'admin/index#index', as: :admin, via: :get

namespace :admin do
  get 'emails' => 'index#emails'
  get 'email' => 'index#email'
  get 'signup_requests' => 'index#signup_requests'
  get 'login' => "index#login"
  get 'graph' => 'index#graph'
  get 'engagement' => 'index#engagement'
  get 'analytics' => "index#analytics"
  post 'refresh_analytics' => "index#refresh_analytics"
  post 'refresh_cms_cache' => 'index#refresh_cms_cache'
  get 'queue' => "index#queue"
  post 'purge_failed_queue' => "index#purge_failed_queue"

  get '/login_as', to: "index#login_as"
  post "/login_as", to: "index#login_as"
  post '/clear_queue_task/:task', to: "index#clear_queue_task", as: :clear_queue_task

  match "/delayed_job" => DelayedJobWeb, :anchor => false, :via => [:get, :post]

  # match '/enable_custom_badges' => 'index#enable_custom_badges', via: [:post]
  # get 'manage'
  resources :companies, only: [:show, :create], constraints: {:id => /[^\/]+/}  do
    member do
      get :users
      post "enable_custom_badges"
      post "enable_admin_dashboard"
      post "enable_achievements"
      post "compile_theme"
      post "toggle_setting"
      put "update_price_package"
      patch :add_users
      post :add_directors
      delete :remove_directors
      post :deposit_money
      post :upload_invoice
      put :update_invoice
      delete :delete_invoice
      put :set_sync_frequency
    end
    resources :subscriptions, except: [:index] do
      member do
        patch :cancel
      end
    end
  end

  resources :recognitions, only: [:index]

  resources :users, only: [:index] do
    collection do
      get :search
    end
  end

  resources :badges, only: [:index, :show]
  resources :subscriptions, only: [:index]
  resources :coupons do
    collection do
      post :sync
    end
  end

  resources :rewards, only: [:index] do
    collection do
      get :transactions
    end
  end

end
