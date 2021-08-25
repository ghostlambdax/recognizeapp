module Report
  class RecognitionsByManager < Report::Recognition
    attr_reader :manager

    def initialize(manager, from, to, opts = {})
      @manager = manager
      @company = manager.company
      super(company, from, to, opts)
    end

    def point_activity_query
      super { |query| query.where(user_id: managed_users) }
    end

    def managed_users
      ::User.where(manager_id: manager.id)
    end


    # Note:
    # - The query should
    #   - include recognitions whose recipients is one of the currently logged in manager's direct reports
    #   - include recognitions
    #     - whose sender is manager's direct report, AND
    #     - whose badge
    #         - is an approvable badge, AND
    #         - has approver set to Role.manager.id, AND
    #         - has resolution strategy set to :any_manager
    #   - and, when the status filter is `pending_recognition`
    #     - should exclude pending recognitions that are within company admin approval scope
    #     - should exclude pending recognitions sent by manager herself, if the company doesn't `allow_manager_to_resolve_recognition_she_sent`
    #
    def recognition_query
      recognitions_set = super.where(user_id: managed_users)

      if status_filter == :pending_approval
        unless @manager.company.allow_manager_to_resolve_recognition_she_sent?
          recognitions_set = exclude_pending_recognitions_sent_by_manager_herself(recognitions_set)
        end

        if company_has_company_admin_approvable_badges?
          recognitions_set = exclude_pending_recognitions_approvable_by_company_admin(recognitions_set)
        end
      end

      if company_has_any_manager_approvable_badges?
        recognitions_set = recognitions_set.or(managed_users_sent_approvable_recognitions_set(super))
      end

      recognitions_set
    end

    def total_pending_recognitions
      # this needs to be independent query to always show the correct pending count in the tertiary nav
      Report::RecognitionsByManager.new(manager, company.created_at, Time.current, status: :pending_approval).recognitions.size
    end

    private

    def company_has_any_manager_approvable_badges?
      company.badges.where(
        requires_approval: true,
        approver: Role.manager.id,
        approval_strategy: ::Badge.approval_strategies[:any_manager]
      ).exists?
    end

    def company_has_company_admin_approvable_badges?
      company.badges.where(
        requires_approval: true,
        approver: Role.company_admin.id,
        approval_strategy: nil
      ).exists?
    end

    # Need to use arel in here because of "structural incompatibility" issue - https://stackoverflow.com/q/40742078
    def exclude_pending_recognitions_approvable_by_company_admin(query_scope)
      query_scope
        .where.not(
        ::Recognition.arel_table[:status_id].eq(::Recognition::States.id_from_name(:pending_approval))
          .and(::Badge.arel_table[:requires_approval].eq(true))
          .and(::Badge.arel_table[:approver].eq(Role.company_admin.id))
      )
    end

    def exclude_pending_recognitions_sent_by_manager_herself(query_scope)
      query_scope
        .where.not(
        ::Recognition.arel_table[:status_id].eq(::Recognition::States.id_from_name(:pending_approval))
          .and(::Recognition.arel_table[:sender_id].eq(@manager.id)))
    end

    # Need to use arel in here because of "structural incompatibility" issue - https://stackoverflow.com/q/40742078
    def managed_users_sent_approvable_recognitions_set(query_scope)
      query_scope
        .where(::Recognition.arel_table[:sender_id].in(managed_users.pluck(:id)))
        .where(::Badge.arel_table[:requires_approval].eq(true))
        .where(::Badge.arel_table[:approver].eq(Role.manager.id))
        .where(::Badge.arel_table[:approval_strategy].eq(::Badge.approval_strategies[:any_manager]))
    end
  end
end
