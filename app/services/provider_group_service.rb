class ProviderGroupService
  Error = Class.new(StandardError)

  def self.safe_yammer_groups_fetch
    error_msg = nil
    groups = begin
      yield
    rescue => e
      error_msg = "Failed to retrieve groups from Yammer - <a href='/auth/yammer' data-method='post'>Click here</a> to reauthenticate".html_safe
      Rails.logger.warn(e.message)
      []
    end

    raise(Error, error_msg) if error_msg

    groups
  end

  def self.yammer_groups_for_company(user)
    safe_yammer_groups_fetch do
      user.yammer_client.get_all_groups
    end
  end

  def self.yammer_groups_for_user(user)
    safe_yammer_groups_fetch do
      user.yammer_client.get_groups_for_user(user.yammer_id)
    end
  end
end

