# skip show since that needs to be accessed unscoped
# NOTE: must be above users to avoid dynamic matching
resources :recognitions, except: [:show, :update, :destroy, :badge] do
  collection do
    post :recognize_instantly
    get :new_chromeless
    get :new_panel
    get :teams
    post :upload_image
  end
  member do
    patch :update, as: "update"
    delete :destroy, as: "destroy"
    put :toggle_privacy
  end
  resources :approvals, controller: "recognition_approvals", only: [:create, :destroy]
end