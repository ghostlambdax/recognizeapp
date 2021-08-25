class SyncGroupService
  Error = Class.new(StandardError)

  def self.fetch_for(user, provider, search_term: nil)
    return [] if user.blank?
    groups = case provider.to_sym
             when :yammer
               fetch_for_yammer(user)
             end
    groups.sort_by(&:name)
  end

  def self.fetch_with_skip_token_for(user, provider, search_term: nil, skip_token: nil)
    return [] if user.blank?
    groups, token = case provider.to_sym
                    when :microsoft_graph
                      fetch_for_microsoft_graph_with_skip_token(user, search_term, skip_token)
                    end
    [groups.sort_by(&:name), token]
  end

  def self.fetch_for_yammer(user)
    company = user.company
    cache_key = "sync_groups_yammer_#{company.name}_#{company.id}"
    yammer_client = YammerClient.new(user.yammer_token, user)

    error_msg = nil
    sync_groups = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      begin
        yammer_client.get_all_groups
      rescue => e
        error_msg = "Failed to retrieve groups from Yammer - <a href='/auth/yammer' data-method='post'>Click here</a> to reauthenticate".html_safe
        Rails.logger.warn(e.message)
        []
      end
    end

    if sync_groups.empty?
      Rails.cache.delete(cache_key)
    end

    raise(Error, error_msg) if error_msg

    sync_groups

  end

  def self.fetch_for_microsoft_graph_with_skip_token(user, search_term, skip_token)
    handle_microsoft_graph_response(user) do |graph_client|
      graph_client.groups_with_skip_token(search_term: search_term, skip_token: skip_token)
    end
  end

  def self.handle_microsoft_graph_response(user)
    microsoft_graph_client = MicrosoftGraphClient.new(user.microsoft_graph_token, user)

    error_msg = nil
    begin
      sync_groups = yield(microsoft_graph_client)
    rescue => e
      error_msg = "Failed to retrieve groups from Microsoft.".html_safe
      Rails.logger.warn(e.message)
      []
    end

    raise(Error, error_msg) if error_msg

    sync_groups

  end

  def self.default_provider(user)
    user.sync_provider
  end
end
