class UserCounts
  attr_reader :company, :opts

  def initialize(company, opts = {})
    @company = company
    @opts = opts
  end

  def base_query
    User.active.where(company_id: company.id)
  end

  def labels
    cr_map = CompanyRole.where(company_id: company.id).inject({}){|m, cr| m[cr.id] = cr.name;m}
    sr_map = Role.all.inject({}){|m, sr| m[sr.id] = sr.long_name;m}
    Hashie::Mash.new(company_roles: cr_map, system_roles: sr_map)
  end

  def unique_users_in_role
    return nil unless opts[:role_ids].present?
    company.get_user_ids_by_company_role_ids(opts[:role_ids]).uniq.length
  end

  def user_counts
    company_role_counts = base_query.joins(:user_company_roles).group(:company_role_id).count
    system_role_counts = base_query.joins(:user_roles).group(:role_id).count
    total = base_query.count
    result = Hashie::Mash.new(company_roles: company_role_counts, system_roles: system_role_counts, total: total, labels: labels)
    result[:unique_users_in_role] = unique_users_in_role if opts[:role_ids].present?
    result
  end
end
