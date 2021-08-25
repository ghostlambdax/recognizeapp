class CreatePointActivitiesForExistingCompletedTasks < ActiveRecord::Migration[5.0]
  def up
    Tskz::CompletedTask.approved.includes(:task, :task_submission).find_each do |completed_task|
      create_point_activity_for_completed_task(completed_task)
    rescue => e
      log("Caught Exception: #{e} (company_id: #{completed_task.company_id}, completed_task id: #{completed_task.id})")
    end
  end

  # Caution: This deletes ALL completed task activities
  #          (including newer activities if they were created later after this feature release)
  def down
    pa_query = PointActivity.completed_tasks
    PointActivityTeam.where(point_activity_id: pa_query.select(:id)).delete_all
    pa_query.delete_all
  end

  private

  def create_point_activity_for_completed_task(completed_task)
    PointActivity.create!(
      activity_type: 'completed_task',
      activity_object: completed_task, # assigns both type & id
      user_id: completed_task.task_submission.submitter_id,
      amount: completed_task.total_points,
      is_redeemable: false, # task points are non-redeemable by default for old companies
      company_id: completed_task.company_id
    )
  end

  def log(message)
    puts message
    Rails.logger.warn(message)
  end
end
