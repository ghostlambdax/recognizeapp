resources :signups, path: :signup do
  collection do
    put :full_name
    put :password
    get :confirm_email
    get :requested
    get :recognize
    get :fb_workplace
    get :yammer
    post :personal_interest
  end
  member do
    get :verify
  end
end
