class Tskz::TaskSubmissionsSerializer < ActiveModel::Serializer
  include TasksHelper
  include DateTimeHelper

  attributes :id, :date, :submitter, :summary, :completed_tasks_count, :pending?
  attributes :edit_endpoint

  def company
    task_submission.company
  end

  def date
    localize_datetime(task_submission.created_at, :friendly_with_time)
  end

  def edit_endpoint
    if context.controller.class == CompanyAdmin::Tskz::CompletedTasksController
      edit_company_admin_task_submission_path(task_submission, network: company.domain)
    else
      edit_manager_admin_task_submission_path(task_submission, network: company.domain)
    end
  end

  def status
    task_submission.status_label
  end

  def summary
    task_submission.description
  end

  def submitter
    task_submission.submitter.full_name
  end

  def task_submission
    object
  end

  def completed_tasks_count
    task_submission.completed_tasks.size
  end
end