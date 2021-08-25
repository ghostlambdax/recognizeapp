# Allow showing a recognition to be unscoped 
# since param is a guid
# NOTE: this takes precedence over scoped routes
#       and thus must be above
get '/recognitions/:id/share/:provider', to: "recognitions#share", :as => "share_recognition"  
resources :recognitions, only: [] do
  resources :comments do
    member do
      put :hide
      put :unhide
    end
  end
  member do
    # need to say: recognition_path(@recognition),
    # takes it away from above put/delete resource route
    get :show, as: "" 
    get :certificate, as: 'certificate'

  end
end
