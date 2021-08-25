resources :task_submissions, only: [:index, :new, :create] do
  collection do
    get :new_chromeless
  end
end