class TaskSubmissionsController < ApplicationController
  filter_access_to :all, attribute_check: true, load_method: :current_user

  def index
    @task_submission = Tskz::TaskSubmission
                         .includes(:completed_tasks => [:task, :tag])
                         .joins(:completed_tasks)
                         .where(submitter_id: current_user.id).last
  end

  def new
    initialize_task_submission
  end

  def new_chromeless
    initialize_task_submission
    render action: "new", layout: "application_chromeless"
  end

  def create
    tasks, description = task_submission_params.values_at(:tasks, :description)
    @task_submission = Tskz::TaskSubmission.submit(submitter: current_user, tasks: tasks, description: description, request_form_id: params[:request_form_id])
    respond_with @task_submission, { location: task_submissions_path }
  end

  private

  def task_submission_params
    task_params = params[:task_submission].delete(:tasks)
    params
      .require(:task_submission)
      .permit(:description)
      .tap do |whitelisted|
        # manual whitelisting for nested hash w/ dynamic keys
        whitelisted[:tasks] = task_params
                                .to_unsafe_h
                                .map do |_i, task|
                                  task.slice("id", "quantity", "comment")
                                      .select { |_k, v| v.is_a? String }
                                end

        # the parsed hashes are converted back to (unpermitted) param-objects when accessed via a parent param-object
        whitelisted[:tasks].each(&:permit!)
      end
  end

  def initialize_task_submission
    @task_submission = Tskz::TaskSubmission.new
  end

  # Enable PaperTrail for this controller. Overrides method in PaperTrail.
  def paper_trail_enabled_for_controller
    true
  end
end
