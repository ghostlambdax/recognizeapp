# frozen_string_literal: true
module AdminRecognitionsHelper
  def pending_recognitions_nav_link
    label = I18n.t('dict.pending').html_safe
    label += "<sup> (<span id='pending-recognition-count'>#{@pending_recognition_count}</span>)</sup>".html_safe if @pending_recognition_count && @pending_recognition_count.positive?
    admin_recognitions_nav_link(manager_or_company_admin_path(status: 'pending_approval'), label)
  end

  def approved_recognitions_nav_link
    admin_recognitions_nav_link(manager_or_company_admin_path(status: 'approved'), I18n.t('dict.approved'))
  end

  def denied_recognitions_nav_link
    admin_recognitions_nav_link(manager_or_company_admin_path(status: 'denied'), I18n.t('dict.denied'))
  end

  def admin_recognitions_nav_link(path, name, klass = nil)
    content_tag(:li, class: ('active' if current_page?(path))) do
      link_to name, path, class: klass
    end
  end

  def manager_or_company_admin_path(status: )
    manager_admin_controller? ? manager_admin_recognitions_path(status: status) : company_admin_recognitions_path(status: status)
  end

  def admin_recognitions_page_header
    case params[:status]
    when 'pending_approval'
      I18n.t('company_admin.recognitions.pending_recognitions')
    when 'denied'
      I18n.t('company_admin.recognitions.denied_recognitions')
    when 'approved'
      I18n.t('company_admin.recognitions.approved_recognitions')
    end
  end
end
