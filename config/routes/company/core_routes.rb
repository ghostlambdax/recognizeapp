resource :company, only: [:show, :update] do
  resources :badges, only: [:new, :create, :destroy, :index, :show] do
    collection do
      patch :update_all
      patch :update_image
      get :remaining
    end

  end

  get :check_list
  get :top_employees_report
  post :update_privacy
  post :update_settings
  put :add_users
  post :resend_invitation_email
  patch :update_point_values
  patch :update_kiosk_mode_key
  patch :update_recognition_limits
  post :sync_yammer_stats
  patch :set_points_to_currency_ratio
  resource :saml_configuration
end