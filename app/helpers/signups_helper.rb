module SignupsHelper
  def get_section_classes

    case section_to_show
    when :first_last_name
      home_class = ""
      first_last_name_class = "current"
      password_class = ""
    when :password
      home_class = ""
      first_last_name_class = ""
      password_class = "current"
    else
      home_class = "current"
      first_last_name_class = ""
      password_class = ""
    end
  
    return home_class, first_last_name_class, password_class
  
  end  
  
  def section_to_show
    if @user.persisted? and @user.first_name.blank?
      :first_last_name
    elsif @user.persisted? and @user.crypted_password.blank?
      :password
    else
      :home
    end
  end

  def terms_consent_checkbox_with_label(form)
    checkbox = form.check_box(:terms_and_conditions, {}, "true", "false")
    text = I18n.t("terms.accept_the_terms_html", terms_path: terms_of_use_path, privacy_policy_path: privacy_policy_path).html_safe
    label = label_tag('user_terms_and_conditions',
                      text, class: 'consent_label')
    safe_join([checkbox, label])
  end
end
