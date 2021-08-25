resources :saml, only: :index do
  collection do
    get :sso
    post :acs
    get :metadata
    get :logout
    put :complete
  end
end      