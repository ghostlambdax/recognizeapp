module AdminTaskSubmissionsConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_task_submission, only: [:edit, :update]
    layout false
  end

  def edit
    @submitter = @task_submission.submitter
    render "company_admin/tskz/task_submissions/edit"
  end

  def update
    @task_submission.assign_attributes(task_submission_params)
    @task_submission.resolve

    respond_with @task_submission
  end

  private

  def task_submission_params
    params
      .require(:task_submission)
      .permit(:approval_comment, :request_form_id, completed_tasks_attributes: %I[id status_id])
  end

  # Enable PaperTrail for this controller. Overrides method in PaperTrail.
  def paper_trail_enabled_for_controller
    true
  end

  def set_task_submission
    @task_submission = @company.task_submissions.find(params[:id])
  end
end
