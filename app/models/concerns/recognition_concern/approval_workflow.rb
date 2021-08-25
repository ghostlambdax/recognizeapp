module RecognitionConcern
  module ApprovalWorkflow
    extend ActiveSupport::Concern

    class States
      include IdNameMethods
      DATA =  [
        [PENDING_APPROVAL = 0, :pending_approval, nil],
        [APPROVED = 1, :approved, nil],
        [DENIED = 2, :denied, nil]
      ].freeze
    end

    POSSIBLE_STATES = %i[pending_approval approved denied].freeze

    POSSIBLE_STATE_TRANSITIONS = [
      { from: :pending_approval, to: :approved },
      { from: :pending_approval, to: :denied }
    ].freeze

    included do
      include ::Approval::Workflow
      include ApprovalWorkflowApprovalStrategy

      approval_workflow_states POSSIBLE_STATES,
                               default: ->(recognition) { recognition.badge&.requires_approval? ? :pending_approval : :approved },
                               possible_state_transitions: POSSIBLE_STATE_TRANSITIONS,
                               states_klass: ApprovalWorkflow::States

      belongs_to :resolver, -> { with_deleted }, class_name: "User", optional: true

      attr_accessor :custom_point_via_resolver # selected during approval workflow

      before_validation :set_system_user_as_resolver, on: :create, unless: -> { badge&.requires_approval? }

      validate :resolved_recognition_have_resolver
      validate :approvable_recognition_dont_have_team_recipients

      after_commit :notify_resolver, on: :create, if: :pending_approval?
      after_commit :notify_recognition_denial, on: :update, if: :status_changed_to_denied?
    end

    module ClassMethods end

    # START - InstanceMethods

    def approve_pending_recognition(resolver:, points:, message: self.message, input_format: nil, request_form_id: nil)
      self.resolver = resolver
      self.message = message
      self.custom_point_via_resolver = points
      self.input_format = input_format if input_format
      self.request_form_id = request_form_id if request_form_id
      self.approved_at = Time.current
      set_status!(:approved)
    rescue Approval::Workflow::InvalidStatusTransitionException
      errors.add(:status_id, "The recognition is no longer pending and can not be approved")
    end

    def deny_pending_recognition(resolver:, message:)
      self.resolver = resolver
      self.denial_message = message if message.present?
      self.denied_at = Time.current
      set_status!(:denied)
    rescue Approval::Workflow::InvalidStatusTransitionException
      errors.add(:status_id, "The recognition is no longer pending and can not be denied")
    end

    def status_changed_to_approved?
      status_changed_to?(:approved)
    end

    def status_changed_to_denied?
      status_changed_to?(:denied)
    end

    def status_changing_to_denied?
      status_id_change.present? && status == :denied
    end

    def underwent_approval_workflow?
      # Check for resolver is done to differentiate between auto approved recognition(that don't require approval
      # workflow, and have system_user set as the resolver) and recognition that undergo approval workflow.
      self.denied? || (self.approved? && self.resolver_id != User.system_user.id)
    end

    def can_be_resolved_by?(user)
      prospective_approval_workflow_resolvers.include?(user)
    end

    private

    def set_recognition_for_approval_workflow
      self.status_id = self.class.status_id_by_name(:pending_approval)
    end

    def set_system_user_as_resolver
      self.resolver = User.system_user
    end

    def approvable_recognition_dont_have_team_recipients
      return unless self.pending_approval?
      return if @team_recipients.blank?

      errors.add(:recipients, I18n.t('activerecord.errors.models.recognition.teams_not_allowed_for_approvable_recognition'))
    end

    def resolved_recognition_have_resolver
      return unless (self.approved? || self.denied?) && resolver.blank?

      errors.add(:resolver_id, "can't be blank")
    end

    def notify_recognition_denial
      return unless self.denied?

      UserNotifier.delay(queue: 'priority').recognition_denial_notifier(self.id)
    end

    def notify_resolver
      return unless self.pending_approval?
      return if self.team_recipients.present? || self.sender.system_user? || self.skip_notifications
      return if self.from_bulk

      recipient_ids = self.user_recipients.map(&:id)
      prospective_approval_workflow_resolvers.each do |resolver|
        UserNotifier.delay(queue: 'priority').resolver_notifier(self.id, resolver.id, recipient_ids)
      end
    end

    # END - InstanceMethods
  end
end
