module RecognitionConcern
  module ApprovalWorkflowApprovalStrategy
    extend ActiveSupport::Concern

    included do
      delegate :prospective_approval_workflow_resolvers, to: :approval_strategy
    end

    def approval_strategy
      @approval_strategy ||= ApprovalStrategy::Base.strategy(self)
    end

  end

  class ApprovalStrategy
    class Base
      attr_reader :recognition

      class << self
        def strategy(recognition)
          return nil unless recognition&.badge&.requires_approval?

          strategy_type(recognition).new(recognition)
        end

        private

        def strategy_type(recognition)
          return CompanyAdmins if recognition.badge.approver == Role.company_admin.id

          manager_strategy = recognition.badge.any_manager_approval_strategy? ? AnyManagers : RecipientsManagers
          # Under rare circumstances, the manager approval strategies can have empty prospective workflow resolvers -
          # see #exclude_sender_from_resolvers? for more. If so, fallback to CompanyAdminApprovalStrategy.
          if manager_strategy.new(recognition).prospective_approval_workflow_resolvers.empty?
            manager_strategy = CompanyAdmins
          end
          manager_strategy
        end
      end

      def initialize(recognition)
        @recognition = recognition
      end

      def prospective_approval_workflow_resolvers
        raise "Not implemented! Must be implemented by client class."
      end
    end

    class CompanyAdmins < Base
      def prospective_approval_workflow_resolvers
        recognition.authoritative_company.company_admins
      end
    end

    class RecipientsManagers < Base

      def unfiltered_prospective_approval_workflow_resolvers
        recognition.user_recipients.map(&:manager)
      end

      def prospective_approval_workflow_resolvers
        resolvers = unfiltered_prospective_approval_workflow_resolvers
        resolvers = exclude_sender_from_resolvers_if_needed(resolvers)
        resolvers.compact.uniq
      end

      private

      def exclude_sender_from_resolvers?(resolvers)
        !recognition.authoritative_company.allow_manager_to_resolve_recognition_she_sent? &&
          recognition.sender.in?(resolvers)
      end

      def exclude_sender_from_resolvers_if_needed(resolvers)
        return resolvers unless exclude_sender_from_resolvers?(resolvers)

        resolvers.reject { |resolver| resolver == recognition.sender }
      end
    end

    class AnyManagers < RecipientsManagers
      def unfiltered_prospective_approval_workflow_resolvers
        super + [recognition.sender.manager]
      end
    end
  end

end
