class Tskz::CompletedTasksSerializer < BaseDatatableSerializer
  include TasksHelper
  include DateTimeHelper

  attributes :id, :tag, :date, :submitter, :task, :status, :points, :quantity, :comment, :task_submission_id, :task_submission, :total_points

  def tag
    completed_task.tag.try(:name)
  end

  def date
    localize_datetime(completed_task.created_at, :friendly_with_time)
  end

  def status
    completed_task.status_label
  end

  def task
    completed_task.task.name
  end

  def submitter
    user = completed_task.task_submission.submitter
    context.link_to user.full_name, context.user_url(user, anchor: "tasks")
  end

  def completed_task
    object
  end

  def task_submission
    Tskz::TaskSubmissionsSerializer.new(completed_task.task_submission, context: context).as_json(root: false)
  end

  def total_points
    completed_task.total_points if completed_task.points
  end

  # Note: Manual escaping is not required for this attribute, as it is rendered via partial (being a "row group")
  def html_safe_attributes
    [:task_submission]
  end
end
