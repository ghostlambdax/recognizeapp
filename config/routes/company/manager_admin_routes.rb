scope :manager, module: :manager_admin, as: :manager_admin do
  resource :dashboard
  resources :users
  resources :redemptions, path: :rewards do
    member do
      put :approve
      put :deny
    end
  end

  draw :recognition_approval_routes

  scope :tasks, module: :tskz do
    resources :completed_tasks, only: [:index], path: :completed
    resources :task_submissions, only: [:edit, :update]
  end

  resources :documents, only: %i[index show destroy]

  namespace :anniversaries do
    resource :calendar, only: [:show] do 
      collection do
        get :queue_export
      end
    end
  end
end
