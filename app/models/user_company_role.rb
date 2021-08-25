class UserCompanyRole < ApplicationRecord
  belongs_to :user
  belongs_to :company_role

  validates :user_id, presence: true, uniqueness: { scope: [:company_role_id], message: I18n.t("activerecord.errors.models.user_company_role.already_company_role"), case_sensitive: true }
  validates :company_role_id, presence: true
end
