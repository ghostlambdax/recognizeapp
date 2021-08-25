module Tskz
  class CompletedTaskObserver < ActiveRecord::Observer
    def after_update(completed_task)
      after_status_changed_to_approved(completed_task) if completed_task.status_changed_to?(:approved)
    end

    private

    def after_status_changed_to_approved(completed_task)
      PointActivity::Recorder.record!(completed_task)
    end
  end
end