require 'will_paginate/array'
module ManagerAdmin
  class Tskz::CompletedTasksDatatable < ::Tskz::CompletedTasksDatatable
    def all_records
      completed_tasks = company.completed_tasks.managed_by(current_user)
      completed_tasks = completed_tasks.order("#{sort_columns_and_directions}") if params[:order].present?
      completed_tasks.includes(:task, :tag, task_submission: :submitter)
        .references(:task, :tag, task_submission: :submitter)
    end
  end
end
