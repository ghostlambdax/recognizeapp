#
# TODO:
# - Notification to relevant people
# - Check Auth of actions (roles based auth???)
#
module Tskz
  class CompletedTask < ActiveRecord::Base
    include Approval::Workflow

    belongs_to :company
    belongs_to :tag, inverse_of: :completed_tasks, optional: true
    belongs_to :task_submission, inverse_of: :completed_tasks
    belongs_to :task, inverse_of: :completed_tasks

    # this is for auto destruction of point activities - copied from Redemption
    has_many :point_activities, -> { PointActivity.completed_tasks }, foreign_key: :activity_object_id, dependent: :destroy

    before_validation :set_company_id, on: :create, if: ->{ self.task.present? }
    before_validation :set_stashed_task_attributes, on: :create, if: ->{ self.task.present? }

    validates_presence_of :company, :task_submission

    POSSIBLE_STATES = %i[pending approved denied].freeze

    POSSIBLE_STATE_TRANSITIONS = [
      { from: :pending, to: :approved },
      { from: :pending, to: :denied }
    ].freeze

    approval_workflow_states POSSIBLE_STATES,
                             default: :pending,
                             possible_state_transitions: POSSIBLE_STATE_TRANSITIONS,
                             states_klass: Tskz::States

    scope :managed_by, ->(user) { joins(task_submission: :submitter).where(users: { manager_id: user.id }) }
    scope :approved, -> { where(status_id: Tskz::States::APPROVED) }
    scope :denied, -> { where(status_id: Tskz::States::DENIED) }

    def approve
      set_status!(:approved)
    end

    def deny
      set_status!(:denied)
    end

    def total_points
      quantity = self.quantity || 1
      points = self.points || 0
      points * quantity
    end

    private

    def set_company_id
      self.company_id = self.task.company_id
    end

    def set_stashed_task_attributes
      self.points = self.task.points
      self.tag_id = self.task.tag_id
    end
  end
end
