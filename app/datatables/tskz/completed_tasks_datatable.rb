# frozen_string_literal: true

require 'will_paginate/array'
# Note: ManagerAdmin::Tskz::CompletedTasksDatatable inherits this class.
class Tskz::CompletedTasksDatatable < Litatable
  COLUMN_SPEC = [
    {attribute: :task_submission_id, visible: false},
    {attribute: :date, orderable: true, sort_column: "completed_tasks.created_at", visible: false},
    {attribute: :submitter, orderable: false},
    {attribute: :comment, orderable: true, sort_column: "completed_tasks.comment"},
    {attribute: :task, orderable: true, sort_column: "tasks.name"},
    {attribute: :tag, orderable: true, sort_column: "tags.name", title: proc { company.custom_labels.task_tags_label }},
    {attribute: :points, orderable: true, sort_column: "completed_tasks.points"},
    {attribute: :quantity, orderable: true, sort_column: "completed_tasks.quantity"},
    {attribute: :total_points, orderable: true, sort_column: "(COALESCE(completed_tasks.quantity, 1) * completed_tasks.points)"},
    {attribute: :status, orderable: true, sort_column: "completed_tasks.status_id"}
  ].freeze

  def all_records
    completed_tasks = company.completed_tasks
    completed_tasks = completed_tasks.order(sort_columns_and_directions.to_s) if params[:order].present?
    completed_tasks
      .includes(:task, :tag, task_submission: :submitter)
      .references(:task, :tag, task_submission: :submitter)
  end

  def group_rows?
    true
  end

  def group_rows_by
    :task_submission_id
  end

  def namespace
    'completed_tasks'
  end

  def search_term_matches_status?(search_term)
    task_statuses = Tskz::States.all.map(&:long_name)
    task_statuses.detect { |status| status.casecmp(search_term).zero? }.present?
  end

  def get_status_match_set(search_term, set)
    task_status_id = Tskz::States.find_by_long_name(search_term).id
    set.where(status_id: task_status_id)
  end

  def filtered_records
    set = self.all_records_filtered_by_date_range(table: :completed_tasks)
    search_term = params.dig(:search, :value)
    return paginated_set(set) unless search_term.present?
    # Check if search term matches tasks status -- BEGINS
    company_status_match_set = search_term_matches_status?(search_term) && get_status_match_set(search_term, set)
    return paginated_set(company_status_match_set) if company_status_match_set.present?
    # Check if search term matches tasks status -- ENDS
    search_columns = %w[users.first_name users.last_name completed_tasks.comment task_submissions.description
                        tasks.name tasks.points tags.name]
    set = filtered_set(set, search_term, search_columns)
    paginated_set(set)
  end

  def serializer
    Tskz::CompletedTasksSerializer
  end

  def row_group_template_path(user)
    "company_admin/tskz/completed_tasks/row_group"
  end

  # extends base method
  def as_json(options = {})
    super.merge({ totalPoints: total_points })
  end

  private

  # count total points for all the resulting records
  def total_points
    filtered_records.limit(nil).approved.sum('completed_tasks.points * COALESCE(completed_tasks.quantity, 1)')
  end
end
