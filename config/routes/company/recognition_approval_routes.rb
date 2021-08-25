resources :recognitions do
  member do
    put :approve
    put :deny
  end
  collection do
    get :queue_export
  end
end
