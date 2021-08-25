get "/getting-started", to: "home#getting_started", as: :getting_started
get '/gamification', to: "home#gamification", as: :gamification
get '/best-recognition-contest-2014', to: "home#contest", as: :contest
get '/goto', to: "users#goto"
get '/resend_verification_email', to: "password_resets#new", as: :resend_verification_email
post '/resend_verification_email', to: 'password_resets#create'
get '/home', to: "home#index", as: :marketing
get '/sign-up', to: "home#sign_up", as: :sign_up
get '/tour', to: "home#tour", as: :tour
get '/engagement', to: "home#engagement", as: :engagement
get '/analytics', to: "home#analytics", as: :analytics
get '/customizations', to: "home#customizations", as: :customizations
get '/pricing', to: "home#pricing", as: :pricing
get '/features', to: "home#features", as: :features
get '/about', to: "home#about", as: :about
get '/yammer-integration', to: "home#extension", as: :extension
get '/why-employee-recognition', to: "home#why", as: :why
get '/privacy', to: "home#privacy_policy", as: :privacy_policy
get '/terms', to: "home#terms_of_use", as: :terms_of_use
get '/maintenance', to: "home#maintenance", :as => :maintenance
get '/coworkers', to: "users#coworkers", as: :coworkers
get '/upgrade/(:code)', to: "home#upgrade", as: :upgrade_promotion
get "/distributed-workforce-infographic", to: "home#distributed_workforce_infographic", as: :distributed_workforce_infographic
get "/year-in-review", to: "mailers#year_in_review"
get "/rewards", to: "home#rewards", as: :rewards
get "/employee-recognition-awards", to: "home#awards", as: "awards"
get "/office-365", to: "home#office365", as: :office365
get "/mobile-employee-recognition", to: "home#mobile", as: :mobile
get '/mobile', to: redirect('/mobile-employee-recognition')
get "/employee-nominations", to: "home#employee_nominations", as: :employee_nominations
get "/slack-employee-recognition", to: redirect("https://zapier.com/apps/slack/integrations/recognize")
get "/slack", to: redirect("https://zapier.com/apps/slack/integrations/recognize")
get "/yammer-gamification", to: "home#yam_gam", as: :yam_gam
get "/idp_check", to: "saml#idp_check"
get "/download", to: "home#download"
get '/signup/verify', to: "password_resets#new"
get '/help', to: "help#index"
get '/employee-anniversaries', to: "home#anniversaries", as: :marketing_anniversaries
get '/outlook', to: "home#outlook", as: :marketing_outlook
get '/sharepoint', to: "home#sharepoint"
get '/engagement-report', to: "home#engagement_report", as: :engagement_report
get '/is_logged_in', to: "home#is_logged_in", as: :is_logged_in
get '/resources', to: "home#resources", as: :resources
get '/outlook-addin', to: "home#outlook_addin", as: :outlook_addin
get '/fb_workplace_placeholder', to: "home#fb_workplace_placeholder", as: :fb_workplace_placeholder
get '/employee-recognition-facebook-workplace', to: 'home#fb_workplace', as: :fb_workplace
get '/facebook-workplace', to: redirect('/employee-recognition-facebook-workplace')
get '/icons', to: 'home#icons', as: :icons
get '/incentives', to: 'home#incentives'
get '/user-rights', to: "home#user_rights"
get '/cookies', to: "home#cookies_policy"
get '/healthcare-employee-recognition', to: 'home#healthcare_landing', as: :healthcare_landing
get '/finance-employee-recognition', to: 'home#banking_landing', as: :banking_landing
get '/banking-employee-recognition-research', to: 'articles#banking_survey', as: :banking_survey

get '/employee-recognition-app-guide', to: "articles#employee_recognition_app_guide"
get '/top-employee-recognition-ideas', to: "articles#top_recognition_ideas"
get '/company-holiday-party-year-end-bonus-guide', to: "articles#holiday_party", as: :holiday_party

get '/data-subject-access-requests', to: redirect('/docs/compliance/Recognize%20Data%20Subject%20Requests.pdf', status: 302), as: :data_subject_access_requests
get '/gdpr', to: redirect('/user-rights')
get '/gdpr/recognize-subprocessors', to: redirect('/gdpr/recognize-subprocessors.pdf')
get '/employee-engagement-glossary', to: 'home#glossary'
get '/employee-recognition-report', to: 'home#demo_survey', as: :demo_survey
get '/employee-reward-ideas', to: "home#reward_ideas", as: :reward_ideas
get '/2019-employee-recognition-trends', to: "articles#employee_recognition_trends_2019", as: :employee_recognition_trends_2019
get '/2019-human-resources-trends', to: "articles#hr_trends_2019", as: :hr_trends_2019
get '/ways-to-be-great-hr-manager', to: 'articles#ways_great_hr_manager', as: :ways_great_hr_manager
get '/healthcare-burnout-employee-recognition-stats', to: 'articles#employee_recognition_stats_for_healthcare', as: :employee_recognition_stats_for_healthcare

get '/employee-recognition-case-studies', to: 'case_study#index', as: 'case_study'
get '/case-study', to: redirect('/employee-recognition-case-studies')
get '/employee-recognition-case-study-in-non-profit', to: 'case_study#teachfirst', as: "teachfirst_case_study"
get '/remote-workforce-case-study', to: 'case_study#goodwaygroup', as: "goodwaygroup_case_study"
get '/customer-service-employee-recognition-case-study', to: 'case_study#metrobank', as: 'metrobank_case_study'
get '/company-value-case-study', to: 'case_study#ideascollide', as: 'ideascollide_case_study'
get '/international-employee-recognition-case-study', to: 'case_study#dealogic', as: 'dealogic_case_study'
get '/safety-healthcare-employee-recognition-case-study', to: 'case_study#corvallisclinic', as: 'corvallisclinic_case_study'
get '/credit-union-employee-recognition-case-study', to: 'case_study#visions_fcu', as: 'visions_fcu_case_study'
get '/employee-recognition-programs', to: 'home#employee_recognition_programs', as: 'employee_recognition_programs'
get '/2019-employee-recognition-report', to: 'articles#employee_recognition_report_2019', as: 'employee_recognition_report_2019'
get '/ways-foster-employee-engagement', to: 'articles#ways_foster_employee_engagement', as: 'ways_foster_employee_engagement'
get '/run-volunteer-program', to: 'articles#run_volunteer_program', as: 'run_volunteer_program'
get '/engage-employees-office-365', to: 'articles#engage_employees_office_365', as: 'engage_employees_office_365'
get '/2020-human-resources-trends', to: 'articles#hr_trends_2020', as: 'hr_trends_2020'
get '/ways-to-combat-coronavirus', to: 'articles#ways_to_combat_coronavirus', as: 'ways_to_combat_coronavirus'
get '/become-a-zoom-power-user', to: 'articles#become_a_zoom_power_user', as: 'become_a_zoom_power_user'
get '/combat-healthcare-burnout', to: 'articles#combat_healthcare_burnout', as: 'combat_healthcare_burnout'
get '/employee-recognition-in-okta', to: 'articles#employee_recognition_in_okta', as: 'employee_recognition_in_okta'

get '/cultivate-positive-remote-work-experience', to: 'articles#cultivate_positive_remote_work_experience', as: 'cultivate_positive_remote_work_experience'
get '/ways-to-use-recognize-during-covid-19', to: 'articles#ways_to_use_recognize_during_covid_19', as: 'ways_to_use_recognize_during_covid_19'
get '/amazing-award-certificates', to: 'articles#amazing_award_certificates', as: 'amazing_award_certificates'


get '/employee-recognition-health-research', to: 'articles#mental_health_research', as: 'mental_health_research'
get '/articles', to: 'articles#index'
get '/microsoft-teams-employee-recognition', to: 'home#microsoft_teams_landing'
get '/website-design-trends-2019', to: 'articles#ui_design_trends_2019', as: :ui_design_trends_2019
get '/videos', to: 'home#videos', as: :recognize_videos
