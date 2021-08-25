# frozen_string_literal: true

module ExternalDataHelper
  def yammer_groups_select_client
    params.values_at("controller", "action").join("_")
  end

  def yammer_groups_select(client, user, opts = {})
    name = begin
      case client
      when :recognitions_new, :recognitions_new_chromeless, :recognitions_new_panel
        "recognition[post_to_yammer_group_id]"
      when :"company_admin/settings_index"
        "company[post_to_yammer_group_id]"
      end
    end

    select_opts = {}
    select_opts[:include_blank] = "Select a group"
    select_opts[:disabled] = true unless user.auth_with_yammer?

    select_tag(name, options_for_select(""), select_opts)
  end

  def prompt_for_yammer_authentication(client, user, reauthenticate: false)
    yammer_long_name = UserSync.providers_to_label_map[:yammer]

    link_to_yammer_opts = {}
    authenticate_info_text = ""
    path_opts = {network: user.company.domain}

    case client
    when :recognitions_new
      redirect_path = new_recognition_path(path_opts)
    when :recognitions_new_chromless
      redirect_path = new_chromeless_recognitions_path(path_opts)
    when :recognitions_new_panel
      redirect_path = new_panel_recognitions_path(path_opts)
    when :recognitions_new_chromless
      redirect_path = new_chromeless_recognition_path(path_opts)
    when :"company_admin/settings_index"
      link_to_yammer_opts.merge!(admin_consent: true)
      redirect_path = company_url(path_opts.merge(anchor: "settings"))
      authenticate_info_text = "You must authenticate with #{yammer_long_name} and be an administrator with #{yammer_long_name} in order to select the group."
    end

    link_to_yammer_opts.merge!(redirect: redirect_path)
    link_to_yammer_opts.merge!(class: "button-yammer-signup button marginBottom20")

    link_text = reauthenticate ? _("Reauthenticate with #{yammer_long_name}") : _("Authenticate with #{yammer_long_name}")

    authenticate_link = link_to_yammer(link_text, link_to_yammer_opts)
    authenticate_info = content_tag(:div, class: "subtleText") { authenticate_info_text }

    safe_join([authenticate_link, authenticate_info])
  end
end
