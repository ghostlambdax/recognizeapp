scope "/:network", constraints: {:network => /[^\/]+/} do
  constraints DomainConstraint.new do
    draw_path_prefix "company"

    get "/" => "recognitions#index", as: "stream"
    get '/grid' => "recognitions#grid", as: "recognitions_grid"
    get '/welcome', to: 'welcome#show', as: "welcome"
    put '/welcome/save_user_count', to: 'welcome#save_user_count', as: :save_user_count

    # SUBSCRIPTION ROUTES
    draw :subscription_routes

    # CORE RESOURCE ROUTES
    draw :core_routes

    # COMPANY ADMIN ROUTES
    draw :company_admin_routes

    # MANAGER ADMIN ROUTES
    draw :manager_admin_routes
    
    resources :departments
    resources :hall_of_fame do 
      collection do
        get :current_winners
        get :group_by_team
        get :group_by_badge
      end
    end
    resources :redemptions, path: 'rewards'

    # TEAMS ROUTES
    draw :teams_routes

    resource :team_assignment, only: [:create, :destroy]

    resources :email_settings
    # resources :invite

    #EXTERNAL(3rd-PARTY) DATA ROUTES
    draw :external_data_routes

    #REPORTS ROUTES
    draw :reports_routes

    # RECOGNITION ROUTES
    draw :recognitions_routes

    resource :identity_provider, path: "idp", only: [:show]

    # NOMINATION ROUTES
    draw :nominations_routes

    # TASK ROUTES
    draw :task_submission_routes

    # USER ROUTES
    draw :user_routes

    # SAML ROUTES
    draw :saml_routes

  end # end constraint
end # end :domain scope
