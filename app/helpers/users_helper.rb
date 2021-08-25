module UsersHelper
  def company_family_options(user)
    user.company.family.collect { |c| [c.name, c.id] }
  end

  def yammer_primary_email(yammer_user)
    User.yammer_primary_email(yammer_user)
  end

  def promote_demote_link(user)
    return "" if current_user == user #do not allow de-adminizing oneself
    if user.company_admin?
      label = "Yes"
      link = demote_from_admin_user_path(user)
    else
      label = "No"
      link = user.external_source.present? ? "" : promote_to_admin_user_path(user)
    end
    return link_to label, link, remote: true, method: :patch
  end

  def promote_demote_executive_link(user)
    if user.executive?
      label = "Yes"
      link = demote_from_executive_user_path(user)
    else
      label = "No"
      link = user.external_source.present? ? "" : promote_to_executive_user_path(user)
    end
    return link_to label, link, remote: true, method: :patch
  end

  def select_company_roles(user)
    return unless current_user.admin? || current_user.company_admin?
    select_tag(
        "user_company_roles",
        options_from_collection_for_select(@company.company_roles, "id", "name", user.company_roles.map(&:id)),
        multiple: true, class: "user-company-role-select",
        data: {
            user: user.id,
            url: user_company_roles_path(network: user.network, user_id: user.id),
        },
    )
  end

  def can_see_user_rewards?(user)
    user.can_view_rewards? &&
      current_user.present? &&
      ( user == current_user ||
        permitted_to?(:manage, current_user.company) ||
        permitted_to?(:show, current_user.company) )
  end

  def select_teams(user)
    select_tag(
        "user_teams",
        options_from_collection_for_select(@company.teams.order(:name), "id", "name", user.teams.map(&:id)),
        multiple: true, class: "user-team-select",
        data: {
            user: user.id,
            url: user_teams_path(network: user.network, user_id: user.id),
        }
    )
  end

  def select_manager(user)
    manager_name = strip_tags(user.manager&.full_name) # html_escape() is redundant here
    select_tag(
      :manager_id,
      options_for_select([[manager_name, user.manager_id]], user.manager_id),
      class: "manager-select",
      data: {
          user: user.id,
          url: manager_user_path(network: user.network, id: user.id),
      }
    )
  end

  def status(user)
    s = user.friendly_status
    if current_user && current_user.admin? && User::PENDING_STATES.include?(user.status.try(:to_sym)) && user.perishable_token.present?
      s += "("+link_to("Verify URL", verify_signup_url(user.perishable_token)) + ")"
    end
    if current_user && current_user.company_admin? && User::PENDING_STATES.include?(user.status.try(:to_sym))
      invite_link_name = user.status.try(:to_sym) == :pending_invite ? "Send invitation" : "Resend invitation"
      s+=  "("+ link_to(invite_link_name, resend_invitation_email_company_path(email: user.email, phone: user.phone, network: user.network),remote: true, method: :post, class: "resend_invitation_email_link") +")"
    end
    s
  end

  def roles(user)
    user.roles.collect { |r| r.long_name.humanize }.join(", ")
  end

  def created_at(user)
    l(user.created_at, format: :friendly_with_time)
  end

  def activate_link(user)
    if user.disabled?
      link_to t("dict.activate"), activate_user_path(user), remote: true, method: :put, class: "button button-chromeless"
    else
      link_to t("dict.disable"), user_path(id: user, network: user.network), remote: true, method: :delete, class: "button button-chromeless"
    end
  end

  def reset_password_links(user)
    user_data = {
      'user-id' => user.id,
      'user-name' => "#{user.first_name} #{user.last_name}".strip,
      'network' => user.network
    }

    html = link_to(
      t("dict.show_password_reset_link"),
      'javascript://',
      id: "show-forgotten-password-link",
      class: "button button-chromeless",
      data: user_data
    )
    html += link_to(
      t("dict.reset_password_link"),
      'javascript://',
      id: "reset-password-link",
      class: "button button-chromeless",
      data: user_data
    ) if user.active?

    html
  end

  def edit_link(user)
    link_to t("company_admin.accounts.edit_profile"), edit_user_path(user), class: "button button-chromeless", data: { turbolinks: false }
  end

  def first_name_link(user)
    link_to(user.first_name || '', user, class: "user")
  end

  def last_name_link(user)
    link_to(user.last_name || '', user, class: "user")
  end

  def email_with_login_link(user)
    e = (user.email).to_s
    e += login_link(user) if current_user && current_user.admin?
    e.html_safe
  end

  def user_phone(user)
    user.phone
  end

  def login_link(user)
    content_tag(:span) do
      content_tag(:sup) do
        concat "(#{link_to "login", admin_login_as_path(id: user.id)})".html_safe
        concat '(yammer)' if user.yammer_token.present?
      end
    end
  end

  def options_for_locales(default_locale)
   options_for_select(CompanySetting.available_locale_options, default_locale)
  end

  def reward_view_details_link(redemption)
    return if [:denied, :pending].include?(redemption.status.to_sym)
    data, redemption_instructions = {}, nil

    if redemption.reward.provider_reward?
      if redemption.response_message.present?
        presenter = redemption.claim_presenter
        redemption_instructions = presenter.instructions
        extra_info = presenter.claim_infos
        data[:extrainfo] = extra_info if extra_info.present?
      end
    else
      # this code is included in both web app and the API for mobile app, should be included in claim_presenter
      redemption_instructions = I18n.t('rewards.company_managed_redemption_instructions') if redemption.approved?

      if (additional_instructions = redemption.additional_instructions)
        data[:redemption_additional_instructions] = format_additional_instructions(additional_instructions)
      end
    end

    data[:instructions] = redemption_instructions if redemption_instructions
    data[:title] = I18n.t('users.rewards.claim_title') if redemption.approved?

    link_to( I18n.t('dict.view_details'),
             'javascript://',
             data: data,
             class: "view-reward-details"
    )
  end

  def format_additional_instructions(additional_instructions)
    additional_instructions_title = I18n.t('redemption.additional_instructions_for_user_title')

    "<div><h5 class='marginTop10'>#{additional_instructions_title}</h5>" +
      "<div class='redemptionInstructions'>#{additional_instructions}</div></div>"
  end

  def users_datatable_user_row_json(user)
    UsersDatatable.new(controller.view_context, @company).send(:row, user).to_json.html_safe
  end

  def department(user)
    user.department
  end

  def country(user)
    user.country
  end

  def can_show_points_tab?
    return true if @user == current_user # ok for looking at your own profile
    return false unless current_user.present? # not ok if logged out
    return false if @user.company_id != current_user.company_id # not ok if you're a different company
    return true if current_user.company_admin? # ok for company admins
    return true if @user.manager_id == current_user.id # ok for their manager
    return false
  end
end
