get '/ms_teams/signup', to: 'ms_teams#signup', as: :ms_teams_signup
get '/ms_teams/start', to: 'ms_teams#start', as: :ms_teams_start
get '/ms_teams/auth', to: 'ms_teams#auth', as: :ms_teams_auth
get '/ms_teams/auth_complete', to: 'ms_teams#auth_complete', as: :ms_teams_auth_complete
get '/ms_teams/tab_config', to: 'ms_teams#tab_config', as: :ms_teams_tab_config
get '/ms_teams/connector_config', to: 'ms_teams#connector_config', as: :ms_teams_connector_config
get '/ms_teams/settings', to: 'ms_teams#settings', as: :ms_teams_settings
post '/ms_teams/settings', to: 'ms_teams#settings'
delete '/ms_teams/settings', to: 'ms_teams#settings', as: :delete_ms_teams_settings
get '/ms_teams/tab_placeholder', to: 'ms_teams#tab_placeholder', as: :ms_teams_tab_placeholder
