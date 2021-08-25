module FbWorkplace::Helpers::BotHelpers
  # key_value_args are the params sent to signup url to be passed along
  # 1. User is in recognize and account is linked(fb_workplace_id is present)
  # 2. User is in recognize and account is not linked
  # 3. User is not in recognize
  # NOTE: action should be both an instance method and a class method
  #       The instance method will be called in the happy path when user account is linked
  #       The class method will be called by Rails controller after signup, See FbWorkplace::SessionVars
  def action_or_signup(action, key_value_args)
    user_in_recognize = get_recognize_user(sender_id) rescue nil

    unless community_id.present?
      Rails.logger.info "NO COMMUNITY ID::  #{community_id}"
      show_link_to_reinstall(action, key_value_args)
    end

    if user_in_recognize.present?
      if user_in_recognize.fb_workplace_id.present?
        do_action(action, key_value_args)
      else
        show_link_to_join_user_account(action, key_value_args)
      end
    else
      show_link_to_join_user_account(action, key_value_args)
    end

    user_in_recognize
  end

  def do_action(action, key_value_args)
    if method(action).arity > 0
      send(action, *key_value_args)
    else
      send(action)
    end
  end

  def show_link_to_reinstall(action, key_value_args)
    fb_workplace_params = key_value_args.merge(
      fb_workplace_class: self.class.to_s.underscore,
      fb_workplace_action: action.to_s,
      fb_workplace_sender_id: sender_id,
      fb_workplace_community_id: community_id
    )
    encoded_fb_workplace_params = Base64.strict_encode64(fb_workplace_params.to_json)

    msg = start_message
    url_params = { fb_workplace_params: encoded_fb_workplace_params, host: Rails.application.config.host, protocol: 'https', referrer: "fb_workplace"}
    url = Rails.application.routes.url_helpers.fb_workplace_signups_url(url_params)
    log "Connection reinstall url: #{url}"
    buttons = [fb_client.web_button(I18n.t('fb_workplace.connect_recognize'), url)]
    fb_client.send_message(sender_id, message: fb_client.group_button(msg, buttons))
  end

  def show_link_to_join_user_account(action, key_value_args)
    return show_link_to_reinstall(action, key_value_args) unless company.present?
    return show_link_to_autolink_user_account(action, key_value_args) if company.settings.autolink_fb_workplace_accounts?

    log "Showing standard link to join account: #{action}"

    # save sender_id and self.value.post_id in database
    message = start_message

    fb_workplace_params = key_value_args.merge(
      network: company.domain,
      fb_workplace_class: self.class.to_s.underscore,
      fb_workplace_action: action.to_s,
      fb_workplace_sender_id: sender_id,
      fb_workplace_community_id: community_id
    )

    encoded_fb_workplace_params = Base64.strict_encode64(fb_workplace_params.to_json)
    url_params = { network: company.domain, fb_workplace_params: encoded_fb_workplace_params, host: Rails.application.config.host, protocol: 'https' }
    url = Rails.application.routes.url_helpers.fb_workplace_signups_url(url_params)
    log "Connection install url: #{url}"
    buttons = [fb_client.web_button(I18n.t('fb_workplace.connect_recognize'), url)]
    fb_client.send_message(sender_id, message: fb_client.group_button(message, buttons))
  end

  def show_link_to_autolink_user_account(action, key_value_args)
    log "Showing autolink to join account: #{action}"

    message = start_message
    buttons = [fb_client.postback_button(I18n.t('fb_workplace.connect_recognize'), {action: "GetStarted", callback_action: action, callback_args: key_value_args}.to_json)]
    fb_client.send_message(sender_id, message: fb_client.group_button(message, buttons))

  end

  def show_link_to_reset_user_account
    message = _('Are you sure you want to reset your account connection?')
    buttons = [fb_client.postback_button(_('Reset connection'), {action: "ResetAccountConnection"}.to_json)]
    fb_client.send_message(sender_id, message: fb_client.group_button(message, buttons))

  end

  def welcome_for_first_time
    fb_client.send_message(sender_id, message: { text: 'Nice work, Recognize is installed! To recognize someone, open the bot menu (3 horizontal lines in the text box), and select "Send Recognition" . Write *help* if you need anything or go to https://recognizeapp.com/help' })
  end

  def help
    message = "To send a recognition, open the Recognize bot menu (3 horizontal lines in the text box), and select \"Send Recognition\".\n\nTry additional commands like: *profile*, *rewards*, *send recognition*, or *manage*.\n\nIf this is your first time using the bot, or you would like to reconnect your account, type *Connect*.\n\nContact Recognize, see the Recognize FAQs, or get resources."
    buttons = [fb_client.web_button('Learn more', 'https://recognizeapp.com/help'), fb_client.web_button('Contact us', 'https://recognizeapp.com/contact')]
    fb_client.send_message(sender_id, message: fb_client.group_button(message, buttons))
  end

  # originally this was implemented as a single argument, but in order to
  # show_link_to_join_user_account, that requires key-value arguments
  # NOTE: When adding links, make sure to add in page.rb FbWorkplace::Webhook::Page::Text
  def show_link(opts = {})
    return show_link_to_join_user_account(:show_link, opts) unless sender.present?

    which = opts[:which]
    default_url_params = { network: company.domain, host: Rails.application.config.host, protocol: 'https' }

    case which
    when :rewards
      message = 'Click below to see your rewards or to redeem.'
      url = Rails.application.routes.url_helpers.redemptions_url(default_url_params)
      wrapped_url = fb_client.get_wrapped_path(url)
      buttons = [fb_client.webview_button('Rewards', wrapped_url)]
    when :profile
      message = 'Click below to see your profile.'
      url = Rails.application.routes.url_helpers.user_url(sender, default_url_params)
      wrapped_url = fb_client.get_wrapped_path(url)
      buttons = [fb_client.webview_button('Profile', wrapped_url)]
    when :admin
      message = 'Manage your account.'
      if sender.company_admin?
        buttons = [
          fb_client.web_button('Dashboard', Rails.application.routes.url_helpers.company_admin_dashboard_url(default_url_params)),
          fb_client.web_button('Customize Badges', Rails.application.routes.url_helpers.company_url(default_url_params.merge(anchor: 'custom_badges'))),
          fb_client.web_button('Top Employees', Rails.application.routes.url_helpers.company_admin_top_employees_url(default_url_params)),
          # fb_client.web_button("Manage Rewards", Rails.application.routes.url_helpers.dashboard_company_admin_rewards_url(default_url_params)),
          # fb_client.web_button("Change Settings", Rails.application.routes.url_helpers.company_url(default_url_params.merge(anchor: "custom_badges")))
        ]
      else
        message = "Sorry, you don't have access to that command."
        # return early, since no buttons
        return fb_client.send_message(sender_id, message: { text: message })
      end
    when :manage
      # NOTE: the logic here is you could be a company admin and a manager. If you are both and you type :manage
      #       show the manager links. Good for demoing. If you are just a company admin and type manage, it will
      #       take you to the company admin.
      if sender.manager?
        message = 'Manage your direct reports.'
        url = Rails.application.routes.url_helpers.manager_admin_dashboard_url(default_url_params)
        buttons = [fb_client.web_button('Manage Recognize', url)]
        buttons = [
          fb_client.web_button('Dashboard', Rails.application.routes.url_helpers.manager_admin_dashboard_url(default_url_params)),
          fb_client.web_button('Users', Rails.application.routes.url_helpers.manager_admin_users_url(default_url_params)),
          fb_client.web_button('Recognitions', Rails.application.routes.url_helpers.manager_admin_recognitions_url(default_url_params)),
          # fb_client.web_button("Manage Rewards", Rails.application.routes.url_helpers.manager_admin_redemptions_url(default_url_params)),
          # fb_client.web_button("Manage Tasks", Rails.application.routes.url_helpers.manager_admin_completed_tasks_url(default_url_params)),
        ]

      elsif sender.company_admin?
        message = 'Manage your account.'
        show_link(which: :admin)
      else
        message = "Sorry, you don't have access to that command."
        # return early, since no buttons
        return fb_client.send_message(sender_id, message: { text: message })
      end
    when :dashboard
      if sender.company_admin?
        message = 'Click below to manage your account.'
        url = Rails.application.routes.url_helpers.company_admin_dashboard_url(default_url_params)
        buttons = [fb_client.web_button('Manage Recognize', url)]
      elsif sender.manager?
        message = 'Click below to manage your account.'
        url = Rails.application.routes.url_helpers.manager_admin_dashboard_url(default_url_params)
        buttons = [fb_client.web_button('Manage Recognize', url)]
      else
        message = "Sorry, you don't have access to that command."
        # return early, since no buttons
        return fb_client.send_message(sender_id, message: { text: message })
      end
    when :"recognize", :"recognise", :"send recognition", :"r"
      message = 'Click below to send recognition.'
      url = Rails.application.routes.url_helpers.new_recognition_url(default_url_params)
      wrapped_url = fb_client.get_wrapped_path(url)
      buttons = [fb_client.webview_button('Send recognition', wrapped_url)]
    when :"customize badges"
      message = 'Click below to customize your badges.'
      url = Rails.application.routes.url_helpers.company_url(default_url_params.merge(anchor: 'custom_badges'))
      buttons = [fb_client.web_button('Customize your badges', url)]
    when :"top employees"
      message = 'Click below to see your top employees.'
      url = Rails.application.routes.url_helpers.company_admin_top_employees_url(default_url_params)
      buttons = [fb_client.web_button('See top employees', url)]
    when :"manage rewards"
      message = 'Click below to see your manage rewards.'
      url = Rails.application.routes.url_helpers.dashboard_company_admin_rewards_url(default_url_params)
      buttons = [fb_client.web_button('Manage rewards', url)]
    when :"change settings"
      message = 'Click below to customize your badges.'
      url = Rails.application.routes.url_helpers.company_admin_url(default_url_params.merge(anchor: 'custom_badges'))
      buttons = [fb_client.web_button('Customize your badges', url)]

    when :connect, :get_started
      return show_link_to_join_user_account(:show_link, opts)
    when :reset
      return show_link_to_reset_user_account
    else
      raise "Unsupported link: #{which}"
    end
    fb_client.send_message(sender_id, message: fb_client.group_button(message, buttons))
  end

  def manager_tags(recipients)
    recipient_manager_groupings = fb_client.managers(recipients.map(&:id))
    manager_tags = recipient_manager_groupings.each_with_object([]) do |recipient, tags|
      tags << recipient.managers.data.map { |m| "@[#{m.id}]" } if recipient.managers.present?
    end.flatten
    manager_tags
  end
end
