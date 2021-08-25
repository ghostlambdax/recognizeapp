class FbWorkplace::Client
  ENDPOINT = 'https://graph.facebook.com/v3.2'
  include FbWorkplace::Helpers::GraphHelpers
  attr_reader :token, :community_id

  def initialize(token, community_id=nil)
    @token = token
    @community_id = community_id
  end

  def company
    @company ||= Company.joins(:settings).where(company_settings: {fb_workplace_community_id: @community_id || community_id}).first
  end

  def connected?
    Recognize::Application.config.rCreds['fb_workplace'].present? && token.present? && community_id.present?
  end

  def community_id
    response = get("/community")
    response.has_key?("id") ? response["id"] : response
  end

  def get(path, params = {}, headers = {})
    opts = {params: params.merge(authentication_params)}.merge(headers)
    begin
      respond RestClient.get full_path(path), opts
    rescue RestClient::ExceptionWithResponse => e
      # ExceptionNotifier.notify_exception(e, data: {path: path, params: params})
      FbWorkplace::Logger.log "Caught exception in GET request(#{path}): #{e.response}"
      FbWorkplace::Logger.log "opts: #{opts}"
      # FbWorkplace::Logger.log "Here: #{Recognize::Application.config.rCreds['fb_workplace']}"
      # FbWorkplace::Logger.log(e)
      Hashie::Mash.new(JSON.parse(e.response)) rescue e.response
    end

  end

  def post(path, params = {}, headers = {})
    begin
      respond RestClient.post full_path(path), params.merge(authentication_params).to_json, {content_type: :json, accept: :json}.merge(headers)
    rescue RestClient::ExceptionWithResponse => e
      ExceptionNotifier.notify_exception(e, data: {path: path, params: params})
      FbWorkplace::Logger.log "Caught exception in POST request(#{path}): #{e.response}"
      FbWorkplace::Logger.log "params: #{params}"
      FbWorkplace::Logger.log "Here: #{Recognize::Application.config.rCreds['fb_workplace']}"
      FbWorkplace::Logger.log(e)
      Hashie::Mash.new(JSON.parse(e.response)) rescue e.response
    end
  end

  def get_all_pages(path, params = {}, headers = {})
    results = []
    counter = 0
    begin
      while((response = get(path, params, headers)) && (after = (response && response['paging'] && response['paging']['cursors']['after'])) && (counter< 5000)) do
        results << response["data"]
        params[:after] = after
        # uri = URI.parse(next_link)
        # query_params = CGI.parse(uri.query)
        # path = "#{uri.path}?#{uri.query}"
        counter += 1
      end
    rescue => e
      FbWorkplace::Logger.log("Failed get_all_pages with #{e.message} for #{path}")
      # ExceptionNotifier.notify_exception(e, {data: {community: @community_id, path: path, params: params, headers: headers}})
    end
    results << response["data"] if response
    results.flatten if response
  end

  def get_community_path(path)
    get_all_pages("/#{community_id}/#{path}")
  end

  def get_post(post_id)
    return if post_id.blank?

    post_data = self.get("/#{post_id}", {"fields": "message,message_tags"})
    message_tags = post_data.message_tags

    recipients = message_tags.select{|t| t.type == "user"}.map do |tag|
      self.user(tag.id)
    end

    {recipients: recipients.compact, message: post_data.message}
  end

  # Due to new FB privacy - need to scope groups to a user
  # So, first need to get FB User id from email
  # Then get groups for that user id
  def groups(fb_workplace_id)
    # get_community_path("groups").map{|m| Hashie::Mash.new(m)} rescue nil
    # user = user_from_email(user_email)
    users_managed_groups(fb_workplace_id)

  end

  def group_members(group_id)
    Rails.cache.fetch("fb-workplace-group-members-#{group_id}", expires_in: 3.hours) do
      get_all_pages("/#{group_id}/members?fields=email").map{|m| Hashie::Mash.new(m)}
    end
  end

  def users_managed_groups(user_id)
    get_all_pages("/#{user_id}/managed_groups").map{|m| Hashie::Mash.new(m)}
  end

  def members
    Rails.cache.fetch("fb-workplace-members-#{community_id}", expires_in: 3.hours) do
      get_community_path("members?fields=email").map{|m| Hashie::Mash.new(m)}
    end
  end

  def member(email, opts = {})
    if opts[:group_id]
      set = group_members(opts[:group_id])
      member = set.detect{|m| m.email == email}
      # if you can't find member in the group, try searching full directory
      if !member.present?
        member = members.detect{|m| m.email == email}
      end
    else
      member = members.detect{|m| m.email == email}
    end
    return member
  end

  def post_to_group(group_id, body, link)
    post("/#{group_id}/feed", body: body, link: link)
  end

  def send_message(recipient_id, payload)
    opts = {recipient: {id: recipient_id}}
    post("/me/messages", opts.merge(payload))
  end

  def send_image_message(sender_id, url)
    send_message(sender_id, message: {attachment: {type: "image", payload: {is_reusable: true, url: url}}})

  end

  def comment(mention_id, summary)
    url = '/' + mention_id + '/comments'
    post(url, {message: summary})
  end

  def user(fbid)
    get("/#{fbid}", fields: "id,email,first_name,last_name,title")
  end

  def user_from_email(email)
    Hashie::Mash.new(get("/#{email}"))
  end

  def set_bot_settings(help_only: true)
    post('/me/messenger_profile', greeting(help_only: help_only))
  end

  def managers(direct_report_ids)
    # this will return an array where each element is a direct report id which will have
    # #managers attribute which itself is an array
    # eg. [{id: "123", managers: [{id: "456"}]}]
    manager_response = self.get("/", {ids: direct_report_ids.join(","), fields: "managers"})
    manager_response.values
  rescue => e
    ExceptionNotifier.notify_exception(e)
    return []
  end

  private

  def full_path(path)
    ENDPOINT + path
  end

  def authentication_params
    time = Time.now.to_i
    secret = Recognize::Application.config.rCreds.dig('fb_workplace', 'app_secret')
    payload = "#{token}|#{time}"
    proof = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, payload)
    p = {
      access_token: token,
      appsecret_proof: proof,
      appsecret_time: time
    }
    Rails.logger.debug "auth params: #{p.except(:access_token)}"
    return p
  end

  def respond(response)
    return Hashie::Mash.new(JSON.parse(response))
  end

end
