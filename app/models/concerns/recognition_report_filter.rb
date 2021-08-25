module RecognitionReportFilter
  def setup_filters
    @sender_filters = []
    @receiver_filters = []

    # Role filters need to be treated differently than the others, so save them for later direct reference
    # The rest of the filters can just be stored into the sender or receiver filter arrays
    @sender_role = SenderRole.new(opts)
    @receiver_role = ReceiverRole.new(opts)

    sender_department = SenderDepartment.new(opts)
    sender_country = SenderCountry.new(opts)
    @sender_filters << sender_department
    @sender_filters << sender_country
    @include_senders = @sender_role.included? || sender_department.included? || sender_country.included?

    receiver_department = ReceiverDepartment.new(opts)
    receiver_country = ReceiverCountry.new(opts)
    @receiver_filters << receiver_department
    @receiver_filters << receiver_country
    @include_receivers = @receiver_role.included? || receiver_department.included? || receiver_country.included?
  end

  def query
    @query ||= begin
                 if @include_senders == @include_receivers
                   opts[:status] ? recognitions_by_different_user_lists(sent_by_users, received_by_users, &status_filter.to_sym) : recognitions_by_different_user_lists(sent_by_users, received_by_users)
                 elsif @include_senders
                   opts[:status] ? recognitions_sent_by(sent_by_users, &status_filter.to_sym) : recognitions_sent_by(sent_by_users)
                 elsif @include_receivers
                   opts[:status] ? recognitions_received_by(received_by_users, &status_filter.to_sym) : recognitions_received_by(received_by_users)
                 else
                   raise 'Unhandled Condition'
                 end
               end
  end

  def sent_by_users
    # Role filters need to run first  because they need to go back
    # to the company in some cases, while the rest are just filters on the users directly
    # that can be chained on to the in-progress query
    senders = @sender_role.included? ? @sender_role.query(@company) : @company.users

    @sender_filters.each do |f|
      senders = f.query(senders)
    end

    senders.pluck(:id)
  end

  def received_by_users
    # Role filters need to run first  because they need to go back
    # to the company in some cases, while the rest are just filters on the users directly
    # that can be chained on to the in-progress query
    receivers = @receiver_role.included? ? @receiver_role.query(@company) : @company.users

    @receiver_filters.each do |f|
      receivers = f.query(receivers) if f.included?
    end

    receivers.pluck(:id)
  end

  class FilteredUserAttribute
    def initialize(opts, filter_attr)
      @filter ||= opts.dig(:filter, filter_attr) || {}
      @filter_id = @filter[:id]
      @included = @filter_id.present?
    end

    def included?
      @included
    end
  end

  class DepartmentFilter < FilteredUserAttribute
    def query(q)
      @included ? q.where(department: @filter_id) : q
    end
  end

  class SenderDepartment < DepartmentFilter
    def initialize(opts)
      super(opts, "sender_department".to_sym)
    end
  end

  class ReceiverDepartment < DepartmentFilter
    def initialize(opts)
      super(opts, "receiver_department".to_sym)
    end
  end

  class CountryFilter < FilteredUserAttribute
    def query(q)
      @included ? q.where(country: @filter_id) : q
    end
  end

  class SenderCountry < CountryFilter
    def initialize(opts)
      super(opts, "sender_country".to_sym)
    end
  end

  class ReceiverCountry < CountryFilter
    def initialize(opts)
      super(opts, "receiver_country".to_sym)
    end
  end

  class RoleFilter < FilteredUserAttribute
    def initialize(opts, filter_attr)
      super(opts, filter_attr)
      @role_id = opts.dig(:filter, filter_attr, :id)
      @scope = opts[:param_scope]
      @status = opts[:status]
    end

    def users_in_role(q)
      if @scope.to_sym == :system_role
        users_in_system_role(q)
      else
        users_in_company_role(q)
      end
    end

    def users_in_system_role(q)
      q.users.includes(:user_roles).where(user_roles: {role_id: @role_id})
    end

    def users_in_company_role(q)
      q.get_users_by_company_role_id(@role_id)
    end

    def query(q)
      @included ? users_in_role(q) : q
    end
  end

  class SenderRole < RoleFilter
    def initialize(opts)
      super(opts, "sender_company_role".to_sym)
    end
  end

  class ReceiverRole < RoleFilter
    def initialize(opts)
      super(opts, "receiver_company_role".to_sym)
    end
  end
end
