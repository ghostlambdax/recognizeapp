class CompanyRolePermission < ApplicationRecord
  belongs_to :permission
  belongs_to :company_role
end
