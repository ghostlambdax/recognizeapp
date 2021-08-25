def draw_path_prefix path=nil
  # :recognize_route_path_prefix stored in defaults is something I made up
  # This is done this way because need a way to break up routes file in a nested manner
  # and the @scope[:defaults] is cleared out in different scopes so it gives us the ability
  # to specify where to lookup the files when in a nested context
  # Otherwise there is no way to know the path for the lookup of the files in the call to #draw
  if path.present?
    @scope[:defaults][:recognize_route_path_prefix] = path if @scope[:defaults].kind_of?(Hash)
  else
    (@scope[:defaults].present? && @scope[:defaults][:recognize_route_path_prefix].present?) ? @scope[:defaults][:recognize_route_path_prefix]+"/" : ""
  end
end

def draw route
  instance_eval(File.read(Rails.root.join("config/routes/#{draw_path_prefix}#{route}.rb")))
end

Rails.application.routes.draw do

  # this definition should be placed at the beginning to override all the relevant redirect-able www routes
  draw :www_redirection_route

  resources :surveys, except: [:new, :edit]
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)

  use_doorkeeper

  resources :inbound_emails, only: [:create]
  resources :chat_threads
  resources :chat_messages

  # API ROUTES
  draw :api_routes
  # Simple Tags resource
  resources :tags, only: [:index]

  root :to => "home#index", :constraints => LoggedInConstraint.new(:logged_out_route)
  root :to => "recognitions#index", :constraints => LoggedInConstraint.new(:logged_in_route), as: :authenticated_root

  get '/proxy.html' => "home#proxy"

  # MISC ROUTES
  resources :password_resets, except: [:destroy]
  resources :support_emails, only: [:new, :create]

  get '/images', to: redirect("/images/default.png")
  get '/support/thanks', to: 'support_emails#support_thanks', as: :support_thanks
  get '/sales/thanks', to: 'support_emails#sales_thanks', as: :sales_thanks
  get '/contact', to: 'support_emails#new', as: :contact
  get '/sales', to: 'support_emails#sales', as: :contact_sales
  get '/sales_simple', to: 'support_emails#sales_simple', as: :sales_simple
  get '/auth/office365', to: redirect("http://recognizeapp.com/auth/microsoft_graph")

  # WORKPLACE ROUTES
  get '/fb_workplace/start', to: 'fb_workplace#start', as: :workplace_start
  get '/fb_workplace/callback', to: 'fb_workplace#callback', as: :workplace_callback
  get '/fb_workplace/failure', to: 'fb_workplace#failure', as: :workplace_failure
  # get '/fb_workplace/deauth', to: 'fb_workplace#deauth', as: :workplace_deauth
  # post '/fb_workplace/deauth', to: 'fb_workplace#deauth'
  match "/fb_workplace/deauth" => "fb_workplace#deauth", as: :workplace_deauth, via: [:get, :post]

  #unsubscribe routes
  match "/unsubscribe/:token", to: "users#unsubscribe", as: :unsubscribe, via: [:get, :patch]

  # MS TEAMS ROUTES
  draw :ms_teams_routes

  # FILE ROUTES
  get '/extensions/recognize.xpi', to: 'files#firefox_extension'

  #ADMIN ROUTES
  draw :admin_routes

  #SESSION ROUTES
  draw :session_routes

  #AUTHENTICATION ROUTES
  draw :authentication_routes

  # STATIC PATHS
  draw :static_routes

  # LANDING PAGES PATHS
  draw :landing_page_routes

  # COMPANY SCOPED ROUTES
  draw :company_routes

  # RECOGNITION ROUTES
  draw :recognition_routes

  # SIGNUP ROUTES
  draw :signup_routes

  draw :cms_routes

  draw :award_generator_routes

  draw :stream_async_routes

  resource :account_chooser, controller: :account_chooser, only: [:show, :update]

  resources :comments

  # This is overriden if there is a robots.txt in `public/ folder`, and it is the preferred method.
  get 'robots.txt' => "home#robots"

  get 'progress-job/:job_id' => 'progress_job/progress#show'

  get "/:network", to: "application#routing_error", constraints: {:network => /[^\/]+/} , format: false
  get "/:network*path", to: "application#routing_error", constraints: {:network => /[^\/]+/} , format: false

end
