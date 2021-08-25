class DeviceToken < ApplicationRecord
  belongs_to :user
  validates :user_id, :token, :platform, presence: true
end