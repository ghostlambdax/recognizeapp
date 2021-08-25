# declarative_authorization ---> https://github.com/ledermann/declarative_authorization
#
# - Multiple attributes in one :if_attribute statement are 'AND'ed.
# - Multiple if_attributes statements are 'OR'ed unless `join_by: :and` is passed
#   to `has_permissions` block.
# - Caution: If a same endpoint has been mentioned for separate role_symbols, the
#   rules are 'OR'ed.

authorization do
  role :guest do
    has_permission_on :award_generator, to: [:service_anniversary]
    has_permission_on :case_study, to: [:index, :teachfirst, :goodwaygroup, :metrobank, :dealogic, :corvallisclinic, :ideascollide, :visions_fcu]

    has_permission_on :articles, to: [:index, :run_volunteer_program, :mental_health_research, :ways_foster_employee_engagement, :employee_recognition_report_2019,
                                      :employee_recognition_stats_for_healthcare, :top_recognition_ideas, :employee_recognition_app_guide,
                                      :holiday_party, :employee_recognition_trends_2019, :hr_trends_2019, :ways_great_hr_manager, :engage_employees_office_365,
                                      :ui_design_trends_2019, :hr_trends_2020, :banking_survey,  :ways_to_combat_coronavirus, :become_a_zoom_power_user,
                                      :combat_healthcare_burnout, :employee_recognition_in_okta, :cultivate_positive_remote_work_experience, :ways_to_use_recognize_during_covid_19,
                                      :amazing_award_certificates]

    has_permission_on :landing_pages, to: [:show]

    has_permission_on :help, to: [:index]
    has_permission_on :home, to: [:index, :tour, :contact, :pricing, :resources,
                                  :why, :privacy_policy, :terms_of_use,
                                  :maintenance, :upgrade, :extension,
                                  :distributed_workforce_infographic, :about,
                                  :robots, :proxy, :sign_up,
                                  :customizations, :contest, :analytics, :engagement,
                                  :gamification, :getting_started, :features, :rewards,
                                  :awards, :office365, :mobile, :employee_nominations,
                                  :slack, :yam_gam, :download, :help, :anniversaries, :outlook, :sharepoint, :engagement_report, :is_logged_in,
                                  :outlook_addin, :fb_workplace, :fb_workplace_placeholder, :icons, :incentives, :user_rights, :cookies_policy, :glossary, :demo_survey, :reward_ideas, :healthcare_landing, :banking_landing, :employee_recognition_programs, :microsoft_teams_landing, :videos
                                 ]

    has_permission_on :user_sessions, to: [:new, :create, :destroy, :ping]
    has_permission_on :authentications, to: [:create, :oauth_failure, :failure, :setup, :new, :auth_status]
    has_permission_on :outlook_authentications, to: [:create]
    has_permission_on :password_resets, to: [:index, :new, :create, :edit, :update]

    has_permission_on :stream_async_load, to: [:comments, :approvals]

    has_permission_on :recognitions, to: [:index, :grid]
    has_permission_on :recognitions, to: [:show, :share] do
      if_attribute :approved? => is{true}, :is_publicly_viewable? => is{true}, :is_private => is{false}
      if_attribute :approved? => is{true}, :allow_guest_access => is{true}
    end
    has_permission_on :recognitions, to: [:certificate] do
      if_attribute :approved? => is{true}, :is_publicly_viewable? => is{true}, :has_proper_recipients_for_certificate? => is{true}
      if_attribute :approved? => is{true}, :allow_guest_access => is{true}, :has_proper_recipients_for_certificate? => is{true}
    end

    has_permission_on :comments, to: [:show], join_by: :and do
      if_attribute :recognition => {comments_allowed?: is{true}}
      if_attribute :is_hidden => is{false}
      if_permitted_to :show, :commentable
    end

    has_permission_on :signups, to: [:create, :full_name, :password, :confirm_email, :verify, :requested, :recognize, :fb_workplace, :personal_interest, :yammer]
    has_permission_on :support_emails, to: [:new, :create, :sales, :sales_simple,  :support_thanks, :sales_thanks]
    has_permission_on :users, to: [:show, :received_recognitions, :sent_recognitions, :direct_reports, :unsubscribe]
    has_permission_on :application, to: [:routing_error]
    has_permission_on :files, to: [:firefox_extension]

    has_permission_on :chat_messages, to: [:new, :create]
    has_permission_on :chat_threads, to: [:new, :create]
    has_permission_on :inbound_emails, to: [:create]
    has_permission_on :identity_providers, to: [:show]
    has_permission_on :saml, to: [:index, :sso, :acs, :metadata, :logout, :complete, :idp_check]
    has_permission_on :account_chooser, to: [:show, :update, :check]
    has_permission_on :surveys, to: [:create]

    has_permission_on :fb_workplace, to: [:callback, :failure, :deauth]
    has_permission_on :ms_teams, to: [:auth, :signup, :start, :tab_config, :connector_config, :tab_placeholder]

    has_permission_on :cms_integrations, to: [:index, :show]
    has_permission_on :cms_product_updates, to: [:index, :show]
    has_permission_on :cms_tags, to: [:show]
    has_permission_on :cms_articles, to: [:show]
    has_permission_on :cms_features, to: [:show]
  end

  role :employee do
    includes :guest

    has_permission_on :company_admin_rewards_points, to: [:show]

    has_permission_on :hall_of_fame, to: [:index, :current_winners, :group_by_team, :group_by_badge] do
      if_attribute :can_view_hall_of_fame? => is{true}
    end

    has_permission_on :tags, to: [:index]

    has_permission_on :redemptions, to: [:restful_actions] do
      if_attribute :can_view_rewards? => is{true}
    end

    has_permission_on :badges, to: [:index, :show, :remaining]
    has_permission_on :welcome, to: [:show, :save_user_count]

    has_permission_on :recognitions, to: [:index, :new_panel, :new_chromeless, :sent, :received, :recognize_instantly]
    has_permission_on :recognitions, to: :upload_image do
      if_attribute image_upload_allowed?: is{true}
    end
    has_permission_on :recognitions, to: [:share] do
      if_attribute :approved? => is{true}
    end
    has_permission_on :recognitions, to: [:create, :new] do
      if_attribute :sender => {:has_sendable_recognition_badges? => is{true}, :company_permits_recognition? => is{true}}
    end
    has_permission_on :recognitions, to: [:show] do
      if_attribute :approved? => is{true}, :is_private => is{true}, :participant_ids => contains{user.id}
      if_attribute :approved? => is{true}, :is_private => is{false},:participant_company_ids => contains{user.company_id}
      if_attribute :pending_approval? => is{true}, :sender_id => is{user.id}
    end

    has_permission_on :recognitions, to: [:teams]

    has_permission_on :recognitions, to: [:certificate] do
      if_attribute :approved? => is{true},
                   :participant_company_ids => contains{user.company_id},
                   :has_proper_recipients_for_certificate? => is{true}
    end
    has_permission_on :recognitions, to: [:edit, :update] do
      if_attribute :approved? => is{true}, :sender_id => is{user.id}
    end
    has_permission_on :recognitions, to: [:destroy, :toggle_privacy] do
      if_attribute :approved? => is{true}, :participant_ids => contains{user.id}
    end
    has_permission_on :recognition_approvals, to: [:create] do
      if_attribute :recognition => {:participant_company_ids => contains{user.company_id}, :participant_ids => does_not_contain{user.id}, :is_private? => is{false} }
    end
    has_permission_on :recognition_approvals, to: [:show] do
      if_attribute :recognition => {:sender_company_id => is{user.company_id}}
    end
    has_permission_on :recognition_approvals, to: [:destroy] do
      if_attribute :giver_id => is {user.id}
    end

    has_permission_on :users, to: [:index, :show, :invite, :send_invitations, :invite_from_yammer, :managed_users,
                                   :coworkers, :get_suggested_yammer_users, :get_relevant_yammer_coworkers, :goto, :update_favorite_teams, :counts]

    has_permission_on :users, to: [:show_completed_tasks] do
      if_attribute id: is { user.id },
                   tasks_enabled_for_company?: is {true}
    end
    has_permission_on :users, to: [:edit, :update, :hide_welcome, :has_read_new_feature, :upload_avatar, :update_slug, :revoke_oauth_token, :destroy] do
      if_attribute id: is{user.id}, network: is{user.network}
    end
    has_permission_on :users, to: [:edit_avatar] do
      if_attribute :company => { restrict_avatar_access: is{false} }
    end
    has_permission_on :reports, to: [:index, :users, :teams, :top_users, :top_yammer_users, :top_yammer_groups]
    has_permission_on :teams, to: [:index, :show, :members]
    has_permission_on :teams, to: [:new, :create] do
      # allow employees to create teams until company is paid
      # then restrict to admins only, for now
      if_attribute :company => { allow_admin_dashboard: false }
    end
    has_permission_on :teams, to: [:show, :edit, :update] do
      if_attribute :managers => contains { user }, :can_be_edited? => is{true}
    end
    has_permission_on :teams, to: [:destroy] do
      if_attribute :managers => contains { user }, :company => { allow_admin_dashboard: false}
    end
    has_permission_on :team_assignments, to: :create
    has_permission_on :team_assignments, to: :destroy

    # this is authorization rules for base class and covers all subclasses
    has_permission_on :team_management_team, to: [:edit, :update] do
      if_attribute :managers => contains { user }
    end

    has_permission_on :comments, to: [:index] do
      if_attribute commentable: { comments_allowed?: is { true } }
    end
    has_permission_on :comments, to: [:create] do
      if_attribute commentable: { participant_company_ids: contains { user.company_id }, comments_allowed?: is { true }, is_private?: is{false}}
      if_attribute commentable: { participant_ids: contains { user.id }, comments_allowed?: is { true }, is_private?: is{true}}
    end
    has_permission_on :comments, to: [:show] do
      if_attribute commentable: { participant_company_ids: contains { user.company_id }, comments_allowed?: is { true } }, is_hidden: is { false }
    end
    has_permission_on :comments, to: [:edit, :update] do
      if_attribute commenter_id: is{user.id}, is_hidden: is{false}
    end
    has_permission_on :comments, to: [:destroy] do
      if_attribute commenter_id: is{user.id}
    end
    has_permission_on :admin_index, to: [:login_as] do
      if_attribute acting_as_superuser: is{true}
    end
    has_permission_on :subscriptions, to: [:new, :create]
    has_permission_on :subscriptions, to: [:show, :edit, :update, :destroy] do
      if_attribute user_id: is{user.id}
      if_attribute status: is{Subscription::PENDING}
    end

    has_permission_on :mailers, to: [:show, :year_in_review]
    has_permission_on :companies, to: [:show, :reports, :check_list] do
      if_attribute allow_admin_dashboard: is{false}
    end

    has_permission_on :nominations, to: [:index, :new, :create, :new_chromeless] do
      if_attribute can_send_nominations?: is{true}
    end
    has_permission_on :task_submissions, to: [:index, :new, :create, :new_chromeless] do
      if_attribute can_submit_tasks?: is{true}
    end

    # START permissions for non paid companies
    has_permission_on(:company_admin_dashboards, to: [:show]) { if_attribute allow_admin_dashboard: is{false} }
    has_permission_on(:company_admin_rewards, to: [:index, :show_sample]) { if_attribute allow_admin_dashboard: is{false} }
    has_permission_on(:company_admin_nominations, to: [:index]) { if_attribute allow_admin_dashboard: is{false} }
    has_permission_on(:company_admin_roles, to: [:index]) { if_attribute allow_admin_dashboard: is{false} }
    has_permission_on(:company_admin_settings, to: [:index]) { if_attribute allow_admin_dashboard: is{false} }
    has_permission_on(:company_admin_tags, to: [:index]) { if_attribute allow_admin_dashboard: is{false} }
    has_permission_on(:company_admin_anniversaries, to: [:index, :queue_export]) { if_attribute allow_admin_dashboard: is{false} }
    has_permission_on(:company_admin_accounts, to: [:show]) { if_attribute allow_admin_dashboard: is{false} }
    has_permission_on(:company_admin_recognitions, to: [:index, :queue_export]) { if_attribute allow_admin_dashboard: is{false} }
    has_permission_on(:company_admin_comments, to: [:index]) { if_attribute allow_admin_dashboard: is{false} }
    has_permission_on(:company_admin_top_employees, to: [:index]) { if_attribute allow_admin_dashboard: is{false} }

    # END permissions for non paid companies

    has_permission_on :device_tokens, to: [:create, :destroy]
    has_permission_on :user_points, to: [:index] do
      if_attribute user_id: is{user.id}
    end

    has_permission_on :fb_workplace, to: [:start]
    has_permission_on :ms_teams, to: [:auth_complete, :settings]
    has_permission_on :external_data, to: [:yammer_groups]
  end

  role :manager do
    includes :employee
    has_permission_on :users, to: [:show_completed_tasks] do
      if_attribute manager_id: is { user.id },
                   tasks_enabled_for_company?: is {true}
    end
    has_permission_on :recognitions, to: [:show] do
      if_attribute :pending_approval? => is{true}, :prospective_approval_workflow_resolvers => contains{user.id}
      if_attribute :manager_ids => contains{ user.id }
    end

    has_permission_on :recognition_approvals, to: [:create], join_by: :and do
      if_attribute :recognition => {participant_company_ids: contains{user.company_id}, participant_ids: does_not_contain{user.id} }
      if_permitted_to :show, :recognition
    end

    has_permission_on :comments, to: [:create], join_by: :and do
      if_attribute commentable: { participant_company_ids: contains { user.company_id }, comments_allowed?: is { true }}
      if_permitted_to :show, :commentable
    end

    has_permission_on :companies, to: [:manage]
    has_permission_on :manager_admin_dashboards, to: [:show]
    has_permission_on :manager_admin_users, to: [:index]
    has_permission_on :manager_admin_recognitions, to: [:index, :approve, :deny, :queue_export]
    has_permission_on :manager_admin_anniversaries_calendars, to: [:show, :queue_export]
    has_permission_on :manager_admin_tskz_completed_tasks, to: [:restful_actions]
    has_permission_on :manager_admin_tskz_task_submissions, to: [:edit, :update]

    has_permission_on :manager_admin_documents, to: [:index]
    has_permission_on :manager_admin_documents, to: [:show, :destroy] do
      if_attribute :requester_id => is { user.id }
      if_attribute :uploader_id => is { user.id }
    end
  end

  role :rewards_manager do
    includes :employee
    has_permission_on :companies, to: [:manage]
    has_permission_on :manager_admin_dashboards, to: [:show]
    has_permission_on :manager_admin_redemptions, to: [:index, :approve, :deny]

  end

  role :company_admin do
    includes :employee

    has_permission_on :users, to: [:promote_to_admin, :demote_from_admin, :promote_to_executive, :demote_from_executive, :destroy, :activate, :nominations]
    has_permission_on :users, to: [:edit, :update, :hide_welcome, :has_read_new_feature, :upload_avatar, :update_slug, :revoke_oauth_token, :destroy, :activate, :manager] do
      if_attribute network: is_in{ user.company.family.map(&:domain) }
    end

    has_permission_on :users, to: [:edit_avatar]
    has_permission_on :users, to: [:show_completed_tasks] do
      if_attribute tasks_enabled_for_company?: is {true}
    end

    has_permission_on :recognitions, to: [:edit, :destroy, :update, :show] do
      if_attribute :participant_company_ids => contains{user.company_id}
    end

    has_permission_on :recognition_approvals, to: [:create], join_by: :and do
      if_attribute :recognition => {participant_company_ids: contains{user.company_id}, participant_ids: does_not_contain{user.id} }
      if_permitted_to :show, :recognition
    end

    has_permission_on :comments, to: [:create], join_by: :and do
      if_attribute commentable: { participant_company_ids: contains { user.company_id }, comments_allowed?: is { true }}
      if_permitted_to :show, :commentable
    end

    has_permission_on :comments, to: [:hide, :unhide, :show, :destroy] do
      if_attribute commentable: { :participant_company_ids => contains{user.company_id} }
    end

    has_permission_on :companies, to: [:show, :update, :recognitions, :update_privacy, :add_users,
                                       :update_settings, :top_employees_report, :resend_invitation_email, :update_point_values,
                                       :update_recognition_limits, :update_kiosk_mode_key, :sync_yammer_stats, :set_points_to_currency_ratio] do
      if_attribute allow_admin_dashboard: is{true}
    end
    has_permission_on :badges, to: [:new, :create, :destroy, :update_all, :update_image]
    has_permission_on :subscriptions, to: [:show, :edit, :update, :destroy] do
      if_attribute company_id: is{user.company_id}, status: is_not{Subscription::CANCELED}
    end

    has_permission_on :teams, to: [:index, :show, :new, :create, :update, :destroy, :nominations]
    has_permission_on :teams, to: [:edit] do
      if_attribute :can_be_edited? => is{true}
    end

    has_permission_on :team_management_team, to: [:edit, :update]
    has_permission_on :rewards, to: [:restful_actions]
    has_permission_on :company_admin_roles, to: [:restful_actions]
    has_permission_on :company_admin_settings, to: [:restful_actions]
    has_permission_on :company_admin_tags, to: [:restful_actions]
    has_permission_on :user_company_roles, to: [:create, :destroy]
    has_permission_on :user_teams, to: [:create, :destroy]
    has_permission_on :company_admin_sync_groups, to: [:create, :index, :destroy]
    has_permission_on :company_admin_user_sync_jobs, to: [:create]
    has_permission_on :saml_configurations, to: [:update]
    has_permission_on :company_admin_dashboards, to: [:show]
    has_permission_on :company_admin_nominations, to: [:index, :award, :votes] do
      # TODO: add permissions for roles here
    end
    has_permission_on :company_admin_campaigns, to: [:show, :archive] do
      # TODO: add permissions for roles here
    end
    has_permission_on :company_admin_nomination_votes, to: [:index]

    has_permission_on :company_admin_anniversaries_settings, to: [:index, :update_badge]
    has_permission_on :company_admin_anniversaries_notifications, to: [:show, :change_roles]
    has_permission_on :company_admin_anniversaries_calendars, to: [:show, :queue_export]
    has_permission_on :company_admin_accounts, to: [:show, :edit, :update, :queue_export, :update_user_password, :user_password_reset_link]
    has_permission_on :company_admin_bulk_mailers, to: [:new, :create]

    has_permission_on :company_admin_top_employees, to: [:index]
    has_permission_on :company_admin_reports, to: [:index]

    has_permission_on :company_admin_rewards, to: [:restful_actions, :template, :provider, :show_sample, :approve_redemption, :deny_redemption, :dashboard]
    has_permission_on :company_admin_redemptions, to: [:index]
    has_permission_on :company_admin_points, to: [:index, :show, :summary, :queue_export]
    has_permission_on :company_admin_rewards_transactions, to: [:index]
    has_permission_on :company_admin_rewards_budgets, to: [:index, :create]
    has_permission_on :company_admin_catalogs, to: [:restful_actions]
    has_permission_on :company_admin_comments, to: [:restful_actions, :queue_export]
    has_permission_on :company_admin_customizations, to: [:show, :update]
    has_permission_on :company_admin_recognitions, to: [:index, :approve, :deny]
    has_permission_on :company_admin_settings, to: [:update, :fb_workplace_groups]
    has_permission_on :company_admin_accounts_spreadsheet_importers, to: [:new, :show_last_import, :upload_data_sheet, :process_data_sheet]
    has_permission_on :company_admin_tskz_tasks, to: [:restful_actions]
    has_permission_on :company_admin_tskz_completed_tasks, to: [:restful_actions]
    has_permission_on :company_admin_tskz_task_submissions, to: [:edit, :update]

    has_permission_on :company_admin_reports_roles, to: [:index]
    has_permission_on :company_admin_reports_teams, to: [:index]
    has_permission_on :company_admin_reports_countries, to: [:index]
    has_permission_on :company_admin_reports_departments, to: [:index]
    has_permission_on :company_admin_documents, to: [:index, :create]
    has_permission_on :company_admin_documents, to: [:show, :destroy] do
      if_attribute :company_id => is { user.company_id }
    end

    has_permission_on :company_admin_custom_field_mappings, to: [:show, :update]
    has_permission_on :company_admin_webhook_endpoints, to: [:index, :create, :update, :destroy, :events, :event_objects, :show_test_payload, :send_test_webhook]
    
  end

  role  :director do
    includes :company_admin
    has_permission_on :departments, to: [:restful_actions]
  end

  role :admin do
    includes :company_admin
    has_permission_on :admin_index, to: [:index, :emails, :email, :signup_requests, :login, :login_as, :analytics, :graph, :engagement, :refresh_analytics, :queue, :purge_failed_queue, :clear_queue_task, :refresh_cms_cache]
    has_permission_on :admin_companies, to: [:show,:create, :enable_custom_badges, :enable_admin_dashboard, :enable_achievements, :users, :add_users, :compile_theme, :add_directors, :remove_directors, :deposit_money, :toggle_setting, :update_price_package, :upload_invoice, :update_invoice, :delete_invoice, :set_sync_frequency]
    has_permission_on :admin_recognitions, to: [:index]
    has_permission_on :admin_users, to: [:index, :search]
    has_permission_on :admin_subscriptions, to: [:index, :show, :create, :update, :new, :edit, :cancel]
    has_permission_on :admin_coupons, to: [:restful_actions, :sync]
    has_permission_on :recognitions, to: :restful_actions
    has_permission_on :badges, to: :restful_actions
    has_permission_on :companies, to: :restful_actions
    has_permission_on :teams, to: [:index, :show, :new, :create, :update, :destroy, :nominations]
    has_permission_on :teams, to: [:edit] do
      if_attribute :can_be_edited? => is{true}
    end
    has_permission_on :tags, to: :restful_actions
    has_permission_on :authorization_rules, to: [:index, :graph, :change, :suggest_change, :read]
    has_permission_on :authorization_usages, to: [:index, :read]

    has_permission_on :chat_messages, to: [:new, :create, :index, :show]
    has_permission_on :chat_threads, to: [:new, :create, :index, :show]
    has_permission_on :admin_rewards, to: [:index, :transactions]
    has_permission_on :company_admin_documents, to: [:show]
  end
end

privileges do

  privilege :restful_actions do
    includes :index, :show, :new, :create, :edit, :update, :destroy
  end
end
