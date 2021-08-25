get "/reports", to: "reports#index", as: :reports
get "/reports/users", to: "reports#users", as: :user_reports
get "/reports/teams", to: "reports#teams", as: :team_reports
get "/reports/top_users", to: "reports#top_users", as: :top_users_reports
get "/reports/top_yammer_users", to: "reports#top_yammer_users", as: :top_yammer_users_reports
get "/reports/top_yammer_groups", to: "reports#top_yammer_groups", as: :top_yammer_groups_reports
# get "/reports/:start_date", to: "reports#previous", as: :previous_report
# get "/reports/badge/:badge_id/:start_date", to: "reports#badge_leaderboard", as: :badge_leaderboard