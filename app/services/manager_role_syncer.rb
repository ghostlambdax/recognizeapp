# frozen_string_literal: true

class ManagerRoleSyncer
  attr_reader :attribute, :role, :company_id

  def self.sync!(company_id)
    new(:manager, company_id).sync!
    new(:rewards_manager, company_id).sync!
  end

  def initialize(attribute, company_id = nil)
    @attribute = attribute
    @company_id = company_id
    @role = Role.send(attribute) # Role.manager or Role.rewards_manager
  end

  def company
    @company ||= Company.find(company_id)
  end

  def reference_set
    rs = (attribute == :manager ? User.not_disabled : Reward.enabled)
    rs.where(company_id: company_id)
  end

  def sync!
    UserRole.bulk_insert do |worker|
      # debugger
      users_to_add_role.each do |u|
        worker.add user_id: u.id, role_id: self.role.id, company_id: self.company_id
      end
    end

    # debugger
    UserRole.where(user_id: users_to_remove_role, role_id: self.role.id, company_id: self.company_id).delete_all
  end

  def existing_managers_by_relationship
    @existing_managers_by_relationship ||= begin
      manager_ids = reference_set.where.not(manager_id: nil).select(:manager_id)
      User.not_disabled.where(id: manager_ids)
    end
  end

  def users_with_manager_role
    @users_with_manager_role ||= begin
      manager_ids = UserRole.where(company_id: self.company_id, role_id: role.id).select(:user_id)
      User.not_disabled.where(id: manager_ids)
    end
  end

  def users_to_remove_role
    # remove the role from users who have it but don't have the relationship
    @users_to_remove_role ||= User.where(id: users_with_manager_role - existing_managers_by_relationship)
  end

  def users_to_add_role
    # managers by relationship who don't have the manager role
    @users_to_add_role ||= existing_managers_by_relationship.where.not(id: users_with_manager_role)
  end
end
