class CompanyDomain < ApplicationRecord
  belongs_to :company,inverse_of: :domains

  validates :company, :domain, presence: true
  validates :domain, uniqueness: { case_sensitive: true }
end
