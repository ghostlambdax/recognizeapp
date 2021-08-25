# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_05_19_104552) do

  create_table "attachments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "file",  collation: "utf8mb4_unicode_ci"
    t.string "type",  collation: "utf8mb4_unicode_ci"
    t.integer "owner_id"
    t.string "owner_type",  collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "company_id"
    t.integer "requester_id"
    t.integer "uploader_id"
    t.string "original_filename"
    t.text "description"
    t.datetime "requested_at"
    t.text "metadata"
    t.date "due_date"
    t.date "date_paid"
    t.index ["company_id"], name: "index_attachments_on_company_id"
    t.index ["owner_id", "owner_type"], name: "index_attachments_on_owner_id_and_owner_type"
    t.index ["requester_id"], name: "attachments_requester_id"
    t.index ["uploader_id"], name: "attachments_uploader_id"
  end

  create_table "authentications", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "provider",  collation: "utf8mb4_unicode_ci"
    t.string "uid",  collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "credentials", collation: "utf8mb4_unicode_ci"
    t.text "extra", size: :long
    t.index ["provider"], name: "index_authentications_on_provider"
    t.index ["user_id"], name: "index_authentications_on_user_id"
  end

  create_table "badges", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name",  collation: "utf8mb4_unicode_ci"
    t.string "short_name",  collation: "utf8mb4_unicode_ci"
    t.string "long_name",  collation: "utf8mb4_unicode_ci"
    t.text "description", collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "company_id"
    t.string "image",  collation: "utf8mb4_unicode_ci"
    t.datetime "disabled_at"
    t.integer "points"
    t.boolean "restricted", default: false
    t.datetime "deleted_at"
    t.boolean "is_instant", default: false
    t.boolean "is_achievement", default: false
    t.integer "achievement_frequency", default: 10
    t.integer "achievement_interval_id", default: 3
    t.integer "sending_frequency"
    t.integer "sending_interval_id"
    t.integer "sending_limit_scope_id", default: 2
    t.boolean "is_nomination", default: false
    t.boolean "is_anniversary", default: false
    t.string "anniversary_template_id"
    t.text "anniversary_message"
    t.text "long_description"
    t.integer "nomination_award_limit_interval_id"
    t.boolean "is_quick_nomination", default: false
    t.boolean "show_in_badge_list", default: true
    t.boolean "allow_self_nomination", default: false
    t.boolean "force_private_recognition", default: false
    t.boolean "requires_approval", default: false
    t.text "point_values"
    t.integer "approval_strategy"
    t.integer "approver"
    t.integer "sort_order", default: 1
    t.index ["company_id"], name: "index_badges_on_company_id"
  end

  create_table "badges_tags", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "badge_id"
    t.integer "tag_id"
  end

  create_table "campaigns", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "badge_id"
    t.integer "company_id"
    t.boolean "is_archived", default: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "interval_id"
    t.index ["badge_id"], name: "index_campaigns_on_badge_id"
    t.index ["company_id"], name: "index_campaigns_on_company_id"
  end

  create_table "catalogs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "currency"
    t.decimal "points_to_currency_ratio", precision: 10, scale: 5, default: "1.0"
    t.boolean "is_enabled", default: false
    t.integer "company_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_catalogs_on_company_id"
  end

  create_table "chat_messages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "chat_thread_id"
    t.text "body"
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_thread_id"], name: "index_chat_messages_on_chat_thread_id"
  end

  create_table "chat_threads", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", limit: 255
    t.text "first_message"
    t.integer "user_id"
  end

  create_table "comments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "commenter_id"
    t.text "content"
    t.integer "commentable_id"
    t.string "commentable_type",  collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_hidden", default: false
    t.string "viewer"
    t.string "viewer_description"
    t.datetime "deleted_at"
    t.integer "company_id"
    t.index ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type"
    t.index ["commenter_id"], name: "index_comments_on_commenter_id"
    t.index ["company_id"], name: "index_comments_on_company_id"
  end

  create_table "companies", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name",  collation: "utf8mb4_unicode_ci"
    t.string "website",  collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "domain",  collation: "utf8mb4_unicode_ci"
    t.string "slug",  collation: "utf8mb4_unicode_ci"
    t.datetime "disabled_at"
    t.integer "users_count", default: 0
    t.integer "sent_recognitions_count", default: 0
    t.datetime "last_recognition_sent_at"
    t.datetime "last_user_created_at"
    t.integer "sent_user_recognitions_count", default: 0
    t.datetime "deleted_at"
    t.integer "received_recognitions_count", default: 0
    t.integer "received_user_recognitions_count", default: 0
    t.datetime "last_recognition_received_at"
    t.datetime "custom_badges_enabled_at"
    t.boolean "global_privacy", default: true
    t.boolean "allow_admin_dashboard", default: false
    t.integer "parent_company_id"
    t.boolean "allow_google_login", default: true
    t.boolean "allow_posting_to_yammer_wall", default: true
    t.boolean "allow_daily_emails", default: false
    t.boolean "allow_instant_recognition", default: true
    t.integer "reset_interval", default: 2
    t.boolean "allow_google_contact_import", default: true
    t.boolean "allow_achievements", default: false
    t.boolean "has_theme", default: false
    t.text "point_values", collation: "utf8mb4_unicode_ci"
    t.boolean "allow_yammer_manager_recognition_notification", default: false
    t.boolean "message_is_required", default: false
    t.integer "recognition_limit_frequency"
    t.integer "recognition_limit_interval_id"
    t.text "salesforce_guid"
    t.text "anniversary_notifieds"
    t.boolean "allow_hall_of_fame", default: false
    t.boolean "allow_yammer_connect", default: true
    t.boolean "allow_invite", default: true
    t.boolean "allow_teams", default: true
    t.boolean "disable_passwords", default: false
    t.boolean "allow_you_stats", default: true
    t.boolean "allow_top_employee_stats", default: false
    t.string "kiosk_mode_key"
    t.boolean "disable_signups", default: false
    t.boolean "allow_rewards", default: true
    t.integer "requested_user_count"
    t.boolean "allow_recognition_sms_notifications", default: false
    t.integer "default_recognition_limit_frequency"
    t.integer "default_recognition_limit_interval_id"
    t.integer "recognition_limit_scope_id", default: 2
    t.integer "default_recognition_limit_scope_id", default: 2
    t.boolean "allow_nominations", default: false
    t.boolean "nomination_message_is_required", default: false
    t.string "post_to_yammer_group_id"
    t.boolean "sync_enabled", default: false, null: false
    t.boolean "sync_teams", default: false, null: false
    t.string "sync_provider", default: "microsoft_graph"
    t.datetime "last_synced_at"
    t.boolean "allow_microsoft_graph_oauth", default: true
    t.text "labels"
    t.boolean "permit_yammer_stats", default: false
    t.boolean "enable_yammer_stats", default: false
    t.datetime "yammer_stats_synced_at"
    t.boolean "limit_sending_to_intracompany_only", default: false
    t.boolean "private_user_profiles", default: true
    t.boolean "allows_private", default: true, null: false
    t.boolean "hide_points", default: false
    t.boolean "restrict_avatar_access", default: false
    t.boolean "show_recognition_tags", default: true
    t.integer "nomination_global_award_limit_interval_id"
    t.boolean "allow_quick_nominations", default: false
    t.boolean "has_set_points_to_currency_ratio", default: true
    t.text "birthday_notifieds"
    t.string "last_accounts_spreadsheet_import_file"
    t.string "last_accounts_spreadsheet_import_problematic_records_file"
    t.string "currency", default: "USD"
    t.boolean "allow_admin_report_mailer", default: true
    t.boolean "allow_manager_report_mailer", default: true
    t.boolean "program_enabled", default: true
    t.string "price_package"
    t.boolean "require_approval_for_provider_reward_redemptions", default: true
    t.integer "last_accounts_spreadsheet_import_results_document_id"
    t.boolean "recognition_wysiwyg_editor_enabled", default: true
    t.string "microsoft_team_id"
    t.index ["deleted_at", "parent_company_id"], name: "index_companies_on_deleted_at_and_parent_company_id"
    t.index ["slug"], name: "index_companies_on_slug"
  end

  create_table "company_customizations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_id"
    t.string "primary_bg_color"
    t.string "secondary_bg_color"
    t.string "primary_text_color"
    t.string "secondary_text_color"
    t.string "action_color"
    t.string "font_family"
    t.string "font_url"
    t.string "youtube_id"
    t.string "action_text_color"
    t.string "email_header_logo"
    t.string "certificate_background"
    t.string "end_user_guide"
    t.text "stylesheet"
    t.string "primary_header_logo"
    t.string "secondary_header_logo"
  end

  create_table "company_domains", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "domain", null: false
  end

  create_table "company_role_permissions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_role_id", null: false
    t.integer "permission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "company_roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "company_id"], name: "index_company_roles_on_name_and_company_id", unique: true
  end

  create_table "company_settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_id"
    t.string "fb_workplace_community_id"
    t.text "fb_workplace_token"
    t.string "fb_workplace_post_to_group_id"
    t.boolean "fb_workplace_enable_post_to_group", default: false
    t.text "profile_badge_ids"
    t.text "yammer_sync_groups"
    t.text "microsoft_graph_sync_groups"
    t.boolean "sync_phone_data", default: true
    t.boolean "sync_service_anniversary_data", default: true
    t.boolean "sync_managers", default: true
    t.boolean "sync_display_name", default: true
    t.string "default_locale", default: "en"
    t.boolean "default_birthday_recognition_privacy", default: false
    t.boolean "default_anniversary_recognition_privacy", default: false
    t.boolean "sync_job_title", default: true
    t.boolean "tasks_enabled", default: true
    t.text "user_ids_to_notify_of_sync_report"
    t.boolean "allow_manager_of_manager_notifications", default: false
    t.boolean "sync_custom_fields", default: false
    t.boolean "default_receive_direct_report_peer_recognition_notifications", default: false
    t.boolean "default_receive_direct_report_anniversary_notifications", default: false
    t.boolean "default_receive_direct_report_birthday_notifications", default: false
    t.integer "authentication_field", default: 0
    t.boolean "sync_email_with_upn", default: false
    t.integer "low_balance_threshold"
    t.string "timezone"
    t.boolean "tasks_redeemable", default: true
    t.boolean "sent_recognition_redeemable", default: true
    t.boolean "received_approval_redeemable", default: true
    t.boolean "sent_approval_redeemable", default: true
    t.boolean "allow_comments", default: true
    t.boolean "workplace_com_share_domain", default: false
    t.text "sync_filters"
    t.string "anniversary_recognition_custom_sender_name"
    t.boolean "sync_department", default: true
    t.boolean "sync_country", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "recognition_editor_settings"
    t.boolean "force_sso", default: true
    t.boolean "require_recognition_tags", default: false
    t.boolean "allow_phone_authentication", default: false
    t.boolean "allow_manager_to_resolve_recognition_she_sent", default: true
    t.boolean "allow_custom_field_mapping", default: false
    t.integer "sync_frequency", default: 1
    t.boolean "recaptcha", default: true
    t.boolean "frontline_logout", default: false
    t.boolean "autolink_fb_workplace_accounts", default: true
    t.boolean "allow_webhooks", default: false
    t.index ["company_id"], name: "index_company_settings_on_company_id", unique: true
  end

  create_table "completed_tasks", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_id", null: false
    t.integer "task_submission_id", null: false
    t.integer "task_id", null: false
    t.integer "status_id", null: false
    t.integer "tag_id"
    t.float "deprecated_value"
    t.integer "quantity"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "points"
    t.index ["company_id"], name: "index_completed_tasks_on_company_id"
    t.index ["tag_id"], name: "index_completed_tasks_on_tag_id"
  end

  create_table "contact_lists", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.text "contacts_raw", size: :long, collation: "utf8mb4_unicode_ci"
    t.index ["user_id"], name: "index_contact_lists_on_user_id", unique: true
  end

  create_table "coupons", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "code",  collation: "utf8mb4_unicode_ci"
    t.text "message", collation: "utf8mb4_unicode_ci"
    t.text "stripe_data", collation: "utf8mb4_unicode_ci"
    t.datetime "deleted_at"
    t.string "css_class",  collation: "utf8mb4_unicode_ci"
    t.text "plan_ids", collation: "utf8mb4_unicode_ci"
  end

  create_table "custom_field_mappings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_id"
    t.string "key"
    t.string "name"
    t.string "provider_key"
    t.string "mapped_to"
    t.string "provider_type"
    t.string "provider_attribute_key"
  end

  create_table "daily_company_stats", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_id"
    t.integer "team_id"
    t.date "date"
    t.integer "total_users"
    t.integer "pending_users"
    t.integer "active_users"
    t.integer "disabled_users"
    t.float "monthly_recipient_res"
    t.float "monthly_sender_res"
    t.float "quarterly_recipient_res"
    t.float "quarterly_sender_res"
    t.float "yearly_recipient_res"
    t.float "yearly_sender_res"
    t.integer "daily_active_users"
    t.integer "weekly_active_users"
    t.integer "monthly_active_users"
    t.integer "quarterly_active_users"
    t.integer "yearly_active_users"
    t.index ["company_id"], name: "index_daily_company_stats_on_company_id"
    t.index ["date"], name: "index_daily_company_stats_on_date"
    t.index ["team_id"], name: "index_daily_company_stats_on_team_id"
  end

  create_table "delayed_jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "priority", default: 0
    t.integer "attempts", default: 0
    t.text "handler", collation: "utf8mb4_unicode_ci"
    t.text "last_error", collation: "utf8mb4_unicode_ci"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by",  collation: "utf8mb4_unicode_ci"
    t.string "queue",  collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "signature"
    t.text "args", size: :long
    t.text "progress_stage"
    t.integer "progress_current", default: 0
    t.integer "progress_max", default: 0
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
    t.index ["queue"], name: "delayed_jobs_queue"
  end

  create_table "device_tokens", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.text "token"
    t.string "platform"
  end

  create_table "email_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "from",  collation: "utf8mb4_unicode_ci"
    t.string "to",  collation: "utf8mb4_unicode_ci"
    t.string "subject",  collation: "utf8mb4_unicode_ci"
    t.text "body", size: :long, collation: "utf8mb4_unicode_ci"
    t.datetime "date"
  end

  create_table "email_settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.boolean "global_unsubscribe", default: false
    t.boolean "new_recognition", default: true
    t.boolean "weekly_updates", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "monthly_updates", default: true
    t.boolean "activity_reminders", default: true
    t.datetime "deleted_at"
    t.boolean "new_comment", default: true
    t.boolean "daily_updates", default: false
    t.boolean "allow_recognition_sms_notifications", default: true
    t.boolean "receive_direct_report_peer_recognition_notifications"
    t.boolean "allow_admin_report_mailer", default: true
    t.boolean "allow_manager_report_mailer", default: true
    t.boolean "receive_direct_report_anniversary_notifications"
    t.boolean "receive_direct_report_birthday_notifications"
  end

  create_table "external_activities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "actor_id", null: false
    t.integer "receiver_id"
    t.string "target_id"
    t.string "target_name"
    t.string "group_id"
    t.integer "company_id", null: false
    t.string "source", null: false
    t.string "source_id", null: false
    t.text "source_metadata"
    t.datetime "created_at", null: false
    t.datetime "synced_at"
    t.index ["actor_id"], name: "index_external_activities_on_actor_id"
    t.index ["company_id"], name: "index_external_activities_on_company_id"
    t.index ["group_id"], name: "index_external_activities_on_group_id"
    t.index ["name", "source_id", "source", "company_id", "actor_id", "receiver_id"], name: "uniq_external_activity", unique: true
    t.index ["name"], name: "index_external_activities_on_name"
    t.index ["receiver_id"], name: "index_external_activities_on_receiver_id"
    t.index ["source"], name: "index_external_activities_on_source"
  end

  create_table "fb_workplace_unclaimed_tokens", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "community_id"
    t.text "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "funds_account_manual_adjustments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.decimal "amount", precision: 32, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "comment"
    t.string "adjustment_type"
    t.string "type"
  end

  create_table "funds_accounts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.decimal "balance", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "company_id"
    t.boolean "recognize_admin", default: false, null: false
    t.boolean "is_primary", default: false
    t.string "currency_code"
    t.index ["company_id"], name: "index_funds_accounts_on_company_id"
  end

  create_table "funds_txns", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "funds_account_id"
    t.string "txn_type"
    t.decimal "amount", precision: 32, scale: 2
    t.decimal "resulting_balance", precision: 32, scale: 2
    t.integer "funds_txnable_id"
    t.string "funds_txnable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.integer "non_unique_key"
    t.integer "catalog_id"
    t.string "amount_currency_code"
    t.index ["funds_account_id", "txn_type", "funds_txnable_id", "funds_txnable_type", "non_unique_key"], name: "funds_txn_uniq_constraint", unique: true
    t.index ["funds_txnable_id", "funds_txnable_type"], name: "index_funds_txns_on_funds_txnable_id_and_funds_txnable_type"
  end

  create_table "inbound_emails", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "sender_email"
    t.string "status"
    t.text "data", size: :long
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["sender_email"], name: "index_inbound_emails_on_sender_email"
  end

  create_table "internal_settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key"
    t.string "value"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "job_status", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "company_id", null: false
    t.integer "initiator_id"
    t.integer "request_count", default: 0, null: false
    t.datetime "started_at"
    t.datetime "stopped_at"
  end

  create_table "line_items", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_id"
    t.integer "subscription_id"
    t.integer "invoice_id"
    t.decimal "amount", precision: 10, scale: 2
    t.string "description"
    t.string "currency", default: "USD"
    t.text "stripe_attributes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "stripe_invoice_id"
  end

  create_table "ms_teams_configs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_id"
    t.string "entity_id"
    t.text "settings", size: :long
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_ms_teams_configs_on_company_id"
  end

  create_table "nomination_votes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "nomination_id"
    t.integer "sender_id"
    t.integer "sender_company_id"
    t.text "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "recognition_id"
    t.boolean "is_quick_nomination", default: false
    t.index ["nomination_id"], name: "index_nomination_votes_on_nomination_id"
    t.index ["sender_company_id"], name: "index_nomination_votes_on_sender_company_id"
    t.index ["sender_id"], name: "index_nomination_votes_on_sender_id"
  end

  create_table "nominations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "recipient_id"
    t.string "recipient_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_awarded", default: false
    t.integer "recipient_company_id"
    t.integer "votes_count"
    t.integer "campaign_id"
    t.datetime "awarded_at"
    t.integer "awarded_by_id"
    t.index ["recipient_company_id"], name: "index_nominations_on_recipient_company_id"
    t.index ["recipient_id", "recipient_type"], name: "index_nominations_on_recipient_id_and_recipient_type"
  end

  create_table "oauth_access_grants", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.integer "application_id", null: false
    t.string "token",  null: false, collation: "utf8mb4_unicode_ci"
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false, collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes",  collation: "utf8mb4_unicode_ci"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "resource_owner_id"
    t.integer "application_id"
    t.string "token",  null: false, collation: "utf8mb4_unicode_ci"
    t.string "refresh_token",  collation: "utf8mb4_unicode_ci"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes",  collation: "utf8mb4_unicode_ci"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name",  null: false, collation: "utf8mb4_unicode_ci"
    t.string "uid",  null: false, collation: "utf8mb4_unicode_ci"
    t.string "secret",  null: false, collation: "utf8mb4_unicode_ci"
    t.text "redirect_uri", null: false, collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "permissions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "target_class", null: false
    t.string "target_action", null: false
    t.integer "target_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plans", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name",  collation: "utf8mb4_unicode_ci"
    t.string "label",  collation: "utf8mb4_unicode_ci"
    t.text "description", collation: "utf8mb4_unicode_ci"
    t.decimal "price_per_user", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_public", default: true
    t.string "interval",  default: "monthly", collation: "utf8mb4_unicode_ci"
    t.text "stripe_attributes", collation: "utf8mb4_unicode_ci"
    t.decimal "amount", precision: 8, scale: 2
    t.string "currency", default: "USD"
  end

  create_table "point_activities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "amount"
    t.string "activity_type"
    t.integer "recognition_id"
    t.integer "user_id"
    t.integer "company_id"
    t.string "network"
    t.string "activity_object_type"
    t.string "activity_object_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "team_id"
    t.integer "badge_id"
    t.boolean "is_redeemable"
    t.datetime "reset_at"
    t.integer "reset_by_id"
    t.index ["activity_object_type", "activity_object_id"], name: "activity_object_index"
    t.index ["badge_id"], name: "index_point_activities_on_badge_id"
    t.index ["company_id", "activity_type", "badge_id", "team_id", "created_at"], name: "pa_c_at_b_t_ts_index"
    t.index ["company_id", "activity_type", "created_at"], name: "pa_c_at_ts_index"
    t.index ["company_id", "is_redeemable"], name: "index_point_activities_on_company_id_and_is_redeemable"
    t.index ["company_id"], name: "index_point_activities_on_company_id"
    t.index ["is_redeemable"], name: "index_point_activities_on_is_redeemable"
    t.index ["network"], name: "index_point_activities_on_network"
    t.index ["recognition_id"], name: "index_point_activities_on_recognition_id"
    t.index ["team_id"], name: "index_point_activities_on_team_id"
    t.index ["user_id"], name: "index_point_activities_on_user_id"
  end

  create_table "point_activity_teams", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "point_activity_id"
    t.integer "team_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "company_id"
    t.integer "recognition_id"
    t.index ["company_id", "recognition_id"], name: "pat_company_recognition"
    t.index ["company_id", "team_id", "recognition_id"], name: "pat_company_team_recognition"
    t.index ["company_id", "team_id"], name: "pat_company_team"
    t.index ["company_id"], name: "index_point_activity_teams_on_company_id"
    t.index ["point_activity_id"], name: "index_point_activity_teams_on_point_activity_id"
    t.index ["team_id", "point_activity_id"], name: "pat_compound"
    t.index ["team_id"], name: "index_point_activity_teams_on_team_id"
  end

  create_table "point_histories", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "owner_id"
    t.string "owner_type",  collation: "utf8mb4_unicode_ci"
    t.integer "points"
    t.integer "team_points"
    t.integer "member_points"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "start_date"
    t.date "end_date"
    t.index ["owner_id", "owner_type"], name: "index_point_histories_on_owner_id_and_owner_type"
  end

  create_table "provider_reward_variants", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "provider_key"
    t.string "name"
    t.string "currency_code"
    t.string "status"
    t.string "value_type"
    t.string "reward_type"
    t.decimal "face_value", precision: 10, scale: 2
    t.decimal "min_value", precision: 10, scale: 2
    t.decimal "max_value", precision: 10, scale: 2
    t.text "countries"
    t.integer "provider_reward_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "provider_rewards", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "provider_key"
    t.string "name"
    t.text "disclaimer", collation: "utf8mb4_unicode_ci"
    t.text "description", collation: "utf8mb4_unicode_ci"
    t.text "short_description", collation: "utf8mb4_unicode_ci"
    t.text "terms", collation: "utf8mb4_unicode_ci"
    t.string "image_url"
    t.string "status"
    t.integer "reward_provider_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "reward_type"
  end

  create_table "recognition_approvals", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "giver_id"
    t.integer "recognition_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "viewer"
    t.string "viewer_description"
    t.integer "company_id"
    t.index ["company_id"], name: "index_recognition_approvals_on_company_id"
    t.index ["giver_id", "recognition_id"], name: "index_recognition_approvals_on_giver_id_and_recognition_id"
    t.index ["giver_id"], name: "index_recognition_approvals_on_giver_id"
    t.index ["recognition_id"], name: "index_recognition_approvals_on_recognition_id"
  end

  create_table "recognition_recipients", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "recognition_id"
    t.datetime "deleted_at"
    t.text "metadata", size: :long, collation: "utf8mb4_unicode_ci"
    t.integer "recipient_company_id"
    t.string "recipient_network",  collation: "utf8mb4_unicode_ci"
    t.integer "user_id"
    t.integer "team_id"
    t.integer "company_id"
    t.integer "sender_company_id"
    t.index ["company_id"], name: "index_recognition_recipients_on_company_id"
    t.index ["deleted_at", "recipient_company_id"], name: "rr_del_rcompany_id"
    t.index ["deleted_at", "sender_company_id", "recipient_company_id"], name: "rrdelscorco"
    t.index ["deleted_at", "sender_company_id"], name: "rrdelsco"
    t.index ["recipient_company_id"], name: "index_recognition_recipients_on_recipient_company_id"
    t.index ["recipient_network"], name: "index_recognition_recipients_on_recipient_network"
    t.index ["recognition_id"], name: "index_recognition_recipients_on_recognition_id"
    t.index ["sender_company_id", "recipient_company_id"], name: "rrscorco"
    t.index ["sender_company_id"], name: "index_recognition_recipients_on_sender_company_id"
    t.index ["team_id"], name: "index_recognition_recipients_on_team_id"
    t.index ["user_id"], name: "index_recognition_recipients_on_user_id"
  end

  create_table "recognition_tags", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "tag_name", null: false
    t.integer "recognition_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recognition_id", "tag_id"], name: "index_recognition_tags_on_recognition_id_and_tag_id"
  end

  create_table "recognitions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "badge_id", null: false
    t.integer "sender_id"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sender_company_id"
    t.integer "approvals_count", default: 0
    t.boolean "is_public_to_world", default: false
    t.string "slug",  collation: "utf8mb4_unicode_ci"
    t.datetime "deleted_at"
    t.text "skills", collation: "utf8mb4_unicode_ci"
    t.string "reason",  collation: "utf8mb4_unicode_ci"
    t.boolean "is_instant", default: false
    t.string "yammer_thread_id",  collation: "utf8mb4_unicode_ci"
    t.boolean "post_to_yammer_wall", default: false
    t.integer "from_inbound_email_id"
    t.boolean "is_private", default: false, null: false
    t.boolean "post_to_fb_workplace", default: false
    t.string "viewer"
    t.string "viewer_description"
    t.boolean "is_cross_company"
    t.integer "resolver_id"
    t.text "denial_message", size: :long
    t.integer "status_id", null: false
    t.integer "earned_points"
    t.string "fb_workplace_post_id"
    t.boolean "from_bulk", default: false
    t.boolean "skip_notifications", default: false
    t.text "message_plain"
    t.string "input_format", default: "text"
    t.datetime "approved_at"
    t.datetime "denied_at"
    t.datetime "bulk_imported_at"
    t.integer "bulk_imported_by_id"
    t.string "post_to_yammer_group_id"
    t.integer "authoritative_company_id"
    t.index ["authoritative_company_id"], name: "auth_company"
    t.index ["badge_id"], name: "index_recognitions_on_badge_id"
    t.index ["deleted_at", "authoritative_company_id", "status_id", "is_private", "badge_id"], name: "status_badge_auth_deleted_company"
    t.index ["deleted_at", "authoritative_company_id", "status_id", "is_private"], name: "stream_index"
    t.index ["deleted_at", "sender_company_id"], name: "index_recognitions_on_deleted_at_and_sender_company_id"
    t.index ["deleted_at"], name: "index_recognitions_on_deleted_at"
    t.index ["sender_company_id"], name: "index_recognitions_on_company_id"
    t.index ["sender_company_id"], name: "index_recognitions_on_sender_company_id_and_recipient_company_id"
    t.index ["sender_id"], name: "index_recognitions_on_sender_id"
    t.index ["slug"], name: "index_recognitions_on_slug"
    t.index ["status_id", "authoritative_company_id", "deleted_at"], name: "status_auth_deleted_company"
    t.index ["status_id", "authoritative_company_id"], name: "status_auth_company"
    t.index ["status_id", "is_private"], name: "index_recognitions_on_status_id_and_is_private"
  end

  create_table "redemptions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "reward_id"
    t.integer "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer "points_at_redemption_time"
    t.string "status", default: "pending"
    t.text "response_message"
    t.integer "approver_id"
    t.datetime "approved_at"
    t.integer "denier_id"
    t.datetime "denied_at"
    t.integer "points_redeemed"
    t.float "value_redeemed"
    t.integer "reward_variant_id", null: false
    t.text "additional_instructions", size: :long
    t.string "value_redeemed_currency_code"
    t.float "value_redeemed_exchange_rate"
    t.decimal "value_redeemed_in_usd", precision: 32, scale: 2
    t.string "viewer"
    t.string "viewer_description"
    t.index ["company_id"], name: "index_redemptions_on_company_id"
    t.index ["deleted_at"], name: "index_redemptions_on_deleted_at"
    t.index ["reward_id"], name: "index_redemptions_on_reward_id"
    t.index ["user_id", "deleted_at"], name: "index_redemptions_on_user_id_and_deleted_at"
    t.index ["user_id"], name: "index_redemptions_on_user_id"
  end

  create_table "reminders", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "no_invites_and_no_recognitions_reminder_sent_at"
    t.datetime "invited_but_no_recognitions_reminder_sent_at"
    t.datetime "inactive_user_reminder_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "has_not_verified_first_warning_sent_at"
    t.datetime "has_not_verified_and_is_now_disabled_sent_at"
    t.datetime "has_not_verified_second_warning_sent_at"
    t.datetime "has_not_verified_third_warning_sent_at"
    t.datetime "deleted_at"
    t.index ["user_id"], name: "index_reminders_on_user_id"
  end

  create_table "reward_providers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "active", default: false
  end

  create_table "reward_variants", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.decimal "face_value", precision: 32, scale: 2
    t.integer "reward_id", null: false
    t.integer "provider_reward_variant_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "label"
    t.integer "quantity"
    t.boolean "is_enabled", default: true
  end

  create_table "rewards", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "title"
    t.integer "company_id"
    t.text "description"
    t.integer "deprecated_points"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean "enabled", default: true
    t.integer "frequency"
    t.integer "interval_id"
    t.integer "manager_id"
    t.string "image"
    t.boolean "published", default: false
    t.integer "quantity"
    t.integer "quantity_interval_id"
    t.integer "provider_reward_id"
    t.float "deprecated_value"
    t.text "additional_instructions", size: :long
    t.string "reward_type"
    t.integer "catalog_id"
    t.index ["catalog_id"], name: "index_rewards_on_catalog_id"
    t.index ["company_id"], name: "index_rewards_on_company_id"
    t.index ["deleted_at"], name: "index_rewards_on_deleted_at"
  end

  create_table "roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name",  collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "saml_configurations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_id"
    t.boolean "is_enabled"
    t.text "entity_id"
    t.text "sso_target_url"
    t.text "slo_target_url"
    t.text "name_identifier_format"
    t.text "certificate"
    t.text "certificate_fingerprint"
    t.text "certificate_fingerprint_algorithm"
    t.boolean "authn_requests_signed"
    t.boolean "logout_requests_signed"
    t.boolean "logout_responses_signed"
    t.boolean "metadata_signed"
    t.string "digest_method"
    t.string "signature_method"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "first_name_uri"
    t.string "last_name_uri"
    t.string "metadata_url"
  end

  create_table "sessions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id",  null: false, collation: "utf8mb4_unicode_ci"
    t.text "data", collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "signup_requests", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "email",  collation: "utf8mb4_unicode_ci"
    t.string "pricing",  collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stripe_charges", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_stripe_customer_id"
    t.string "stripe_charge_id"
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_stripe_customer_id"], name: "index_stripe_charges_on_user_stripe_customer_id"
  end

  create_table "subscriptions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_count"
    t.string "email",  collation: "utf8mb4_unicode_ci"
    t.integer "user_id"
    t.string "stripe_customer_token",  collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.integer "company_id"
    t.integer "plan_id"
    t.text "department", collation: "utf8mb4_unicode_ci"
    t.string "coupon_code",  collation: "utf8mb4_unicode_ci"
    t.decimal "unit_price", precision: 10, scale: 2
    t.integer "quantity"
    t.string "payment_method", limit: 255
    t.date "billing_start_date"
    t.integer "invoice_number"
    t.text "notes"
    t.decimal "amount", precision: 8, scale: 2
    t.string "charge_interval", limit: 255
    t.string "currency", default: "USD"
    t.boolean "archived", default: false
    t.integer "status", default: 0
    t.string "billing_label"
    t.string "contract_title"
    t.text "contract_body"
    t.string "contract_signature"
    t.date "sign_date"
  end

  create_table "support_emails", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name",  collation: "utf8mb4_unicode_ci"
    t.string "email",  collation: "utf8mb4_unicode_ci"
    t.text "message", collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type",  collation: "utf8mb4_unicode_ci"
    t.string "salesforce_guid", limit: 255
    t.string "phone"
  end

  create_table "surveys", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "data", size: :long
    t.string "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tags", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_recognition_tag", default: false
    t.boolean "is_task_tag", default: false
    t.index ["company_id"], name: "index_tags_on_company_id"
  end

  create_table "task_submissions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_id", null: false
    t.text "description"
    t.integer "submitter_id", null: false
    t.integer "status_id", null: false
    t.integer "approver_id"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "approval_comment", size: :long
    t.index ["company_id", "submitter_id"], name: "index_task_submissions_on_company_id_and_submitter_id"
    t.index ["company_id"], name: "index_task_submissions_on_company_id"
    t.index ["submitter_id"], name: "index_task_submissions_on_submitter_id"
  end

  create_table "tasks", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "name", null: false
    t.integer "tag_id"
    t.integer "interval_id"
    t.integer "frequency"
    t.float "deprecated_value"
    t.datetime "disabled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "points"
    t.index ["company_id"], name: "index_tasks_on_company_id"
  end

  create_table "team_managers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "manager_id"
    t.integer "team_id"
    t.index ["manager_id"], name: "index_team_managers_on_manager_id"
    t.index ["team_id", "manager_id"], name: "index_team_managers_on_team_id_and_manager_id"
    t.index ["team_id"], name: "index_team_managers_on_team_id"
  end

  create_table "teams", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "company_id"
    t.string "name",  collation: "utf8mb4_unicode_ci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "network",  collation: "utf8mb4_unicode_ci"
    t.integer "created_by_id"
    t.integer "received_recognitions_count"
    t.integer "total_member_points", default: 0
    t.integer "total_team_points", default: 0
    t.integer "interval_team_points", default: 0
    t.integer "interval_member_points", default: 0
    t.datetime "synced_at"
    t.integer "yammer_id"
    t.string "microsoft_graph_id"
    t.datetime "last_nomination_awarded_at"
    t.index ["network"], name: "index_teams_on_network"
  end

  create_table "user_company_roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "company_role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "company_role_id"], name: "index_user_company_roles_on_user_id_and_company_role_id", unique: true
  end

  create_table "user_permissions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "permission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "company_id"
    t.index ["company_id", "role_id"], name: "index_user_roles_on_company_id_and_role_id"
    t.index ["company_id"], name: "index_user_roles_on_company_id"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "user_sessions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_stripe_customers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "stripe_customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_user_stripe_customers_on_user_id"
  end

  create_table "user_teams", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "team_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["team_id"], name: "index_user_teams_on_team_id"
    t.index ["user_id", "team_id"], name: "index_user_teams_on_user_id_and_team_id"
    t.index ["user_id"], name: "index_user_teams_on_user_id"
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "first_name", limit: 255
    t.string "last_name", limit: 255
    t.string "email"
    t.integer "company_id"
    t.text "bio", size: :medium
    t.string "crypted_password", limit: 255
    t.string "password_salt", limit: 255
    t.string "persistence_token", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "perishable_token",  default: "", null: false
    t.integer "invited_by_id"
    t.datetime "invited_at"
    t.string "status", limit: 255
    t.datetime "verified_at"
    t.string "slug", limit: 255
    t.text "job_title"
    t.integer "received_recognitions_count", default: 0
    t.integer "sent_recognitions_count", default: 0
    t.integer "given_recognition_approvals_count", default: 0
    t.integer "total_points", default: 0
    t.boolean "has_read_welcome", default: false
    t.integer "login_count", default: 0, null: false
    t.integer "failed_login_count", default: 0, null: false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string "current_login_ip", limit: 255
    t.string "last_login_ip", limit: 255
    t.integer "invited_users_count", default: 0
    t.datetime "first_login_at"
    t.text "has_read_features", size: :medium
    t.datetime "deleted_at"
    t.string "network", limit: 255
    t.text "contacts_raw", size: :long
    t.string "yammer_id", limit: 255
    t.date "start_date"
    t.integer "interval_points", default: 0
    t.string "salesforce_guid", limit: 255
    t.string "locale",  default: "en"
    t.integer "from_inbound_email_id"
    t.integer "redeemable_points", default: 0, null: false
    t.string "phone"
    t.datetime "last_auth_with_saml_at"
    t.datetime "synced_at"
    t.datetime "disabled_at"
    t.date "birthday"
    t.string "microsoft_graph_id"
    t.integer "manager_id"
    t.string "unique_key"
    t.datetime "last_nomination_awarded_at"
    t.integer "redeemed_points", default: 0
    t.boolean "receive_birthday_recognitions_privately", default: false
    t.boolean "receive_anniversary_recognitions_privately", default: false
    t.string "outlook_identity_token"
    t.string "display_name"
    t.string "fb_workplace_id"
    t.string "employee_id"
    t.string "custom_field0"
    t.string "custom_field1"
    t.string "custom_field2"
    t.string "custom_field3"
    t.string "custom_field4"
    t.string "custom_field5"
    t.string "custom_field6"
    t.string "custom_field7"
    t.string "custom_field8"
    t.string "custom_field9"
    t.string "user_principal_name"
    t.text "favorite_team_ids"
    t.string "timezone"
    t.string "department"
    t.string "country"
    t.datetime "last_sms_sent_at"
    t.index ["company_id", "deleted_at"], name: "index_users_on_company_id_and_deleted_at"
    t.index ["company_id", "employee_id"], name: "index_users_on_company_id_and_employee_id", unique: true
    t.index ["company_id", "status", "deleted_at"], name: "company_status"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["deleted_at", "email"], name: "index_users_on_deleted_at_and_email"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["manager_id"], name: "index_users_on_manager_id"
    t.index ["network"], name: "index_users_on_network"
    t.index ["slug"], name: "index_users_on_slug"
    t.index ["unique_key"], name: "index_users_on_unique_key", unique: true
  end

  create_table "versions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "webhook_endpoints", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "target_url", null: false
    t.string "request_method", default: "POST", null: false
    t.string "request_headers"
    t.string "subscribed_event", null: false
    t.text "payload_template"
    t.boolean "is_active", default: false
    t.integer "owner_id"
    t.integer "company_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "authentication_token_ciphertext"
    t.text "conditions_template"
    t.boolean "escape_all_values", default: true
    t.string "description"
    t.index ["company_id"], name: "index_webhook_endpoints_on_company_id"
    t.index ["owner_id"], name: "index_webhook_endpoints_on_owner_id"
  end

  create_table "webhook_events", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "name", null: false
    t.text "request_payload"
    t.text "request_method"
    t.text "request_url"
    t.text "request_headers"
    t.text "response_payload"
    t.text "response_headers"
    t.text "response_status_code"
    t.integer "endpoint_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["endpoint_id"], name: "index_webhook_events_on_endpoint_id"
  end

  add_foreign_key "catalogs", "companies"
  add_foreign_key "rewards", "catalogs"
  add_foreign_key "webhook_endpoints", "companies"
  add_foreign_key "webhook_endpoints", "users", column: "owner_id"
  add_foreign_key "webhook_events", "webhook_endpoints", column: "endpoint_id"
end
