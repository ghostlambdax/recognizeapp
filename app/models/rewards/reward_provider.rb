module Rewards
  class RewardProvider < ApplicationRecord

    has_many :provider_rewards

    validates :name, uniqueness: {case_sensitive: true}

    def activate!
      update_column(:active, true)
    end

    def deactivate!
      update_column(:active, false)
    end

    def get_client
      self.name.camelize.constantize
    end

  end
end
