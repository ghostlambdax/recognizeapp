module TasksHelper
  def nav_link_to_tasks_index
    content_tag(:li, class: ('active' if active_subnav?("/tasks/completed"))) do
      link_to 'Tasks', company_admin_completed_tasks_path
    end
  end

  def nav_link_to_tasks_setup
    content_tag(:li, class: ('active' if active_subnav?("/tasks/manage"))) do
      link_to 'Manage', company_admin_tasks_path
    end
  end

  def tasks_allowed_roles_label(task)
    task.roles_with_permission(:send).map(&:name).join(', ')
  end
end