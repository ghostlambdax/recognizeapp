class SamlConfiguration < ApplicationRecord
  belongs_to :company

  validates :company_id, presence: true
end
