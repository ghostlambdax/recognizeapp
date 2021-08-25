resources :teams do
  scope module: 'team_management' do
    resource :members, only: [:edit, :update]
    resource :managers, only: [:edit, :update]          
  end
  member do 
    get :nominations
    get :members
  end
end