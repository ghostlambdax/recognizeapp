module Tskz
  class TaskSubmission < ApplicationRecord
    include Approval::Workflow

    enable_duplicate_request_preventer

    belongs_to :company, inverse_of: :task_submissions
    belongs_to :submitter, class_name: 'User'
    belongs_to :approver, class_name: 'User', optional: true
    has_many :completed_tasks, inverse_of: :task_submission, dependent: :destroy, class_name: "Tskz::CompletedTask"

    accepts_nested_attributes_for :completed_tasks

    after_commit :notify_manager, on: :create

    validates_associated :completed_tasks
    validates_presence_of :company, :submitter, :status_id
    validates_presence_of :approver_id, if: :resolved?
    validates_presence_of :completed_tasks, message: I18n.t("tskz/task_submission.attributes.completed_tasks.blank")

    POSSIBLE_STATES = %i[pending resolved].freeze

    POSSIBLE_STATE_TRANSITIONS = [
      { from: :pending, to: :resolved }
    ].freeze

    approval_workflow_states POSSIBLE_STATES,
                             default: :pending,
                             possible_state_transitions: POSSIBLE_STATE_TRANSITIONS,
                             states_klass: Tskz::States

    # TODO: implement check interval settings to see whether a user can submit a task
    #       with the tasks interval restriction settings


    def before_set_status(old_state, new_state)
      if old_state == :pending && new_state == :resolved
        touch(:resolved_at)
        self.approver_id = current_paper_trail_user.id
      end
    end

    def after_set_status(old_state, new_state)
      if old_state == :pending && new_state == :resolved
        Tskz::TaskSubmissionNotifier.delay(queue: 'priority').notify_submitter(self)
      end
    end

    class << self
      def submit(submitter:, tasks:, description:, request_form_id:)
        attrs = {
          submitter: submitter,
          company: submitter.company,
          request_form_id: request_form_id
        }
        attrs[:description] = description if description.present?

        new(attrs).tap do |task_submission|
          build_completed_tasks(task_submission, tasks, submitter) if tasks.present?
          task_submission.save
        end
      end

      private

      def build_completed_tasks(task_submission, tasks, submitter)
        authorized_tasks = submitter.completable_tasks(id_only: true)
        tasks.each do |task_details|
          task_id = task_details[:id]
          task_id = task_id.to_i if task_id.present?
          next unless task_id && authorized_tasks.include?(task_id)

          task_submission.completed_tasks
            .new(task_id: task_id)
            .assign_attributes(task_details.slice(:quantity, :comment))
        end
      end
    end

    def resolve
      set_status!(:resolved)
    rescue ::Approval::Workflow::InvalidStatusTransitionException
      errors.add(:status_id, "^The task submission is no longer pending and can not be resolved")
    end

    private

    def notify_manager
      if submitter.manager
        Tskz::TaskSubmissionNotifier.delay(queue: 'priority').notify_manager(self)
      else
        submitter.company.company_admins
          .reject {|admin| admin == submitter}
          .each do |admin|
            Tskz::TaskSubmissionNotifier.delay(queue: 'priority').notify_company_admin(admin, self)
          end
      end
    end
  end
end
