class Role 
  include IdNameMethods


  DATA = [
    [SYSTEM_USER=0, :system_user, "System User"],
    [ADMIN=1, :admin, "Admin"],
    [COMPANY_ADMIN=2, :company_admin, "Company Admin"],
    [TEAM_LEADER=3, :team_leader, "Team Leader"],
    [EMPLOYEE=4, :employee, "Employee"],
    [EXECUTIVE=5,:executive, "Executive"],
    [DIRECTOR=6, :director, "Director"],
    [MANAGER=7, :manager, "Manager"],
    [REWARDS_MANAGER=8, :rewards_manager, 'Rewards Manager']
  ]


  # Class accessors
  # Eg. Role.admin, Role.company_admin
  class << self
    DATA.each do |role_data|
      role_value, role_sym, _short_name = *role_data
      define_method("#{role_sym}") { find(role_value)} 
    end

    def company_user_ids_by_role_id(company, role_id, include_disabled: false)
      # return only non-disabled users unless specifically asked for
      # which so far hasn't occurred. But providing support
      # for it none the less. Generally when asking for users by role
      # you primarily want active users. The only possible context might
      # be the Company Admin > Accounts page or possibly reports that
      # were specifically built to include disabled users. 

      case role_id
      when MANAGER
        pluck = 'distinct users.manager_id'
        users = company.users.where.not(manager_id: nil)
        users = users.not_disabled unless include_disabled

      when REWARDS_MANAGER
        pluck = 'distinct rewards.manager_id'
        users = company.rewards.with_not_disabled_manager


      else
        pluck = 'distinct users.id'
        users = company.users.joins(:user_roles).where(user_roles: {role_id: role_id})
        users = users.not_disabled unless include_disabled
      end

      user_ids = users.pluck(pluck)
      return user_ids
    end

  end

  module UserMethods
    # User interrogators
    # Eg. user.employee?, user.admin?
    DATA.each do |role_data|
      role_value, role_sym, _short_name = *role_data
      define_method("#{role_sym}?") { has_role?(role_value) }
    end

    def roles
      _roles = user_roles.map{|ur| Role.find(ur.role_id)}
      Role::Collection.new(self, _roles)
    end

    def roles=(new_roles)
      new_roles.each{|role| roles << role}
    end

    private
    def has_role?(role_id)
      case role_id
      when Role.manager.id, Role.rewards_manager.id
        roles.map(&:id).include?(role_id)
      else
        # this is theoretically more performant for non-virtual roles
        user_roles.any?{|ur| ur.role_id == role_id}
      end
    end
  end  

  class Collection < Array
    attr_reader :user

    def initialize(user, roles)
      @user = user
      super(roles)
    end

    def <<(new_role)
      user.user_roles.create(role_id: new_role.id)
      super
    end

  end
end
