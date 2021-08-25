scope :company, module: :company_admin, as: :company_admin do
  resources :recognitions do
    collection do
      get :queue_export
    end
  end

  resources :settings
  resource :dashboard
  resources :roles
  resources :tags
  resources :top_employees, only: [:index]

  draw :recognition_approval_routes

  resources :points, only: [:index, :show], path: :points do
    collection do
      get :summary
      get :queue_export
    end

    member do
      get :queue_export
    end
  end

  scope :rewards do
    resources :redemptions, only: [:index]
    resources :rewards_transactions, only: [:index], path: :transactions
    # resources :rewards_budgets, only: [:index, :create], path: :budget
  end

  resources :rewards, except: [:index, :new, :create] do
    collection do
      get :show_sample
      put :approve_redemption
      put :deny_redemption
    end
  end

  resources :catalogs, except: [:destroy, :show] do
    nested do
      scope :rewards do
        resources :rewards_budgets, only: [:index, :create], path: :budget
      end
    end

    resources :rewards, only: [:index, :new, :create] do
      collection do
        get :dashboard
        get :template
        get :provider
      end
    end
  end

  resources :sync_groups, only: [:index, :create, :destroy]
  resources :user_sync_jobs, only: [:create]
  resources :nominations, only: [:index] do
    member do
      get :votes
      post :award
    end
  end

  namespace :nominations do
    resources :votes, path: :votes, as: :votes, controller: "/company_admin/nomination_votes"
  end

  resources :campaigns, only: [:show] do
    member do
      post :archive
    end
  end

  namespace :anniversaries do
    resources :settings, only: [:index] do
      collection do
        put :update_badge
      end
    end

    resource :notifications, only: [:show] do
      collection do
        put :change_roles
      end
    end
    resource :calendar, only: [:show] do
      collection do
        get :queue_export
      end
    end
  end

  resource :accounts_spreadsheet_importers, only: [:new, :show] do
    collection do
      get :show_last_import
      put :upload_data_sheet
      put :process_data_sheet
    end
  end
  resource :accounts, only: [:show, :edit, :update] do
    collection do
      get :queue_export
      patch :update_user_password
      get :user_password_reset_link
    end
  end
  resource :bulk_mailer, only: [:new, :create]
  resources :comments do
    collection do
      get :queue_export
    end
  end
  resource :customizations, only: [:show, :update]
  resource :settings, only: [:update] do
    collection do
      get :fb_workplace_groups
    end
  end

  scope :tasks, module: :tskz do
    resources :completed_tasks, only: [:index], path: :completed
    resources :tasks, path: :manage
    resources :task_submissions, only: [:edit, :update]
  end

  resources :reports, only: [:index]

  scope :reports, module: :reports, as: :reports do
    resources :roles, only: [:index]
    resources :teams, only: [:index]
    resources :countries, only: [:index]
    resources :departments, only: [:index]
  end

  resources :documents, only: %i[index create show destroy]

  resource :custom_field_mappings, only: [:show, :update]
  resources :webhook_endpoints, only: [:index, :create, :update, :destroy] do
    member do
      get :events
      get :event_objects
      patch :show_test_payload
      patch :send_test_webhook
    end
  end
end
