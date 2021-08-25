require 'will_paginate/array'
class Tskz::TasksDatatable < DatatablesBase
  COLUMN_TABLE_MAP = {
    "task_name" => "tasks.name",
    "points" => "tasks.points",
    "tag" => "tags.name",
    "roles" => "roles",
    "status" => "tasks.disabled_at",
    "actions" => "actions"
  }.freeze

  # method override
  def column_attributes
    @column_attributes ||= {
      2 => { title: company.custom_labels.task_tags_label },
      3 => { orderable: false },
      5 => { orderable: false }
    }
  end

  def all_records
    tasks = company.tasks
              .includes(:completed_tasks).references(:completed_tasks)
              .includes(:tag).references(:tag)
    tasks = tasks.order("#{sort_columns_and_directions}") if params[:order].present?
    tasks
  end

  def default_order
    "[[ 1, \"desc\" ]]"
  end

  def columns
    column_name_array = column_table_map.keys
    column_index_array = column_name_array.size.times.to_a
    # Merge same-index elements of two arrays; Eg: [0, 1].zip(["id", "name"]) => [[0, "id"], [1, "name"]]
    column_index_and_name_array = column_index_array.zip(column_name_array)
    column_index_and_name_array.to_h
  end

  def column_table_map
    COLUMN_TABLE_MAP
  end

  def namespace
    'tasks'
  end

  def task_statuses
    serializer.status_labels
  end

  def search_term_matches_status?(search_term)
    task_statuses.values.detect { |status| status.casecmp(search_term).zero? }.present?
  end

  def search_term_matches_company_role?(search_term)
    company.company_roles.where("company_roles.name = ?", search_term).present?
  end

  def get_company_role_match_set(search_term, set)
    permissions = Permission
                    .where(target_class: 'Tskz::Task', target_action: 'send')
                    .includes(:company_roles).references(:company_roles)
                    .where('company_roles.name = ?', search_term)
    task_ids = permissions.pluck(:target_id).compact
    set.where(id: task_ids)
  end

  def get_status_match_set(search_term, set)
    search_term_is_for_disabled = task_statuses[:disabled].casecmp(search_term).zero?
    is_or_is_not = search_term_is_for_disabled ? "IS NOT" : "IS"
    set.where("tasks.disabled_at #{is_or_is_not} NULL")
  end

  def filtered_records
    search_term = params.dig(:search, :value)
    set = all_records
    return paginated_set(set) unless search_term.present?
    # Check if search term matches company role or tasks tatus -- BEGINS
    # Here, `company_role_match_set` has higher precedence than `company_status_match_set` if both present.
    company_role_match_set = search_term_matches_company_role?(search_term) && get_company_role_match_set(search_term, set)
    return paginated_set(company_role_match_set) if company_role_match_set.present?
    company_status_match_set = search_term_matches_status?(search_term) && get_status_match_set(search_term, set)
    return paginated_set(company_status_match_set) if company_status_match_set.present?
    # Check if search term matches company role or tasks tatus -- ENDS
    # Only check for other conditions if neither `company_role_match_set` and `task_status_match_set` is present.
    search_columns = %w[tasks.name tasks.points tags.name]
    set = filtered_set(set, search_term, search_columns)
    paginated_set(set)
  end

  def serializer
    Tskz::TasksSerializer
  end
end