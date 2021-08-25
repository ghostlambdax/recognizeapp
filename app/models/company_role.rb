class CompanyRole < ApplicationRecord
  belongs_to :company
  # has_many :user_roles # DEPRECATE 2016/06/24- i don't think this is used
  has_many :user_company_roles, dependent: :delete_all
  has_many :users, through: :user_company_roles
  has_many :company_role_permissions, dependent: :delete_all
  has_many :direct_permissions, through: :company_role_permissions, source: "permission"

  validates :name, presence: true, uniqueness: { scope: :company_id, case_sensitive: false }
  validates :company_id, presence: true

  alias_attribute :long_name, :name

  def as_json(options = {})
    options[:only] ||= [:id, :name]
    options[:methods] ||= [:long_name]
    super(options)
  end

  def grant(permission)
    direct_permissions << permission
  end

  def revoke(permission)
    direct_permissions.delete(permission)
  end

  def permissions
    direct_permissions
  end

  def self.user_count_by_role(company)
    CompanyRole.joins(:user_company_roles).where(company_id: company.id).group("company_roles.id").count
  end
end
