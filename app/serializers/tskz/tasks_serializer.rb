class Tskz::TasksSerializer < BaseDatatableSerializer
  include TasksHelper

  attributes :task_name, :points, :status, :tag, :roles, :actions

  def self.status_labels
    {
      enabled: I18n.t("dict.active"),
      disabled: I18n.t("dict.disabled")
    }
  end

  def task_name
    object.name
  end

  def tag
    object.tag.try(:name)
  end

  def roles
    tasks_allowed_roles_label object
  end

  def status
    object.enabled? ? self.class.status_labels[:enabled] : self.class.status_labels[:disabled]
  end

  # Caution: This column is rendered as-is without escaping.
  def actions
    html_str = ''
    html_str << context.link_to(
      "Edit",
      edit_company_admin_task_path(object, network: object.company.domain),
      class: "button button-chromeless"
    )
    disable_or_delete = object.has_completed_tasks? ? 'Disable' : 'Delete'
    html_str << context.link_to(
      object.enabled? ? disable_or_delete : 'Activate',
      company_admin_task_path(object, network: object.company.domain),
      method: :delete,
      remote: true,
      data: { confirm: "Are you sure?", taskId: object.id },
      class: "task-status-toggle button button-chromeless danger"
    )
    html_str
  end

  def html_safe_attributes
    [:actions]
  end
end