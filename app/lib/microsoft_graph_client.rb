require 'hashie'

class MicrosoftGraphClient
  attr_reader :api

  BASE_URL = "https://graph.microsoft.com/v1.0"

  delegate :user, :credentials, :token, :refresh_token, :expires_at, :expiry, :refresh!, to: :api

  def initialize(token, user)
    @api = RestClientWrapper.new(token, user)
  end

  def current_user
    MicrosoftUser.new( get("/me") )
  end

  def photo
    get_raw("/me/photo/$value")
  rescue RestClient::ResourceNotFound
    return nil
  end

  def get_all_users
    users
  end

  # Microsoft does not support grabbing all attributes in all endpoints that pull users
  # Eg, the /users endpoint does not support grabbing hireDate and birthday
  # even though /user/<id> does and /groups/<id>/members does.
  # So, you need to check if its accessible in all of those endpoints.
  # This is why USERS_EXCLUDE_ATTRS exists - to exclude hireDate and birthday
  # from the /users endpoint.
  #
  # Note: The default `businessPhones` attr is ignored here as it is not needed
  USER_API_ATTRIBUTES = %w[id displayName givenName jobTitle mail mobilePhone officeLocation
                           preferredLanguage surname userPrincipalName hireDate birthday department country].freeze

  def user(id, additional_attributes = [])
    select_query = select_query_for_attributes(USER_API_ATTRIBUTES + additional_attributes)
    MicrosoftUser.new(get("/users/#{id}?#{select_query}"))
  end

  USERS_EXCLUDE_ATTRS = %w[hireDate birthday].freeze
  def users(additional_attributes = [])
    user_attributes = (USER_API_ATTRIBUTES + additional_attributes).reject {|r| USERS_EXCLUDE_ATTRS.include?(r) }
    select_query = select_query_for_attributes(user_attributes)
    u = get_all_pages("/users?#{select_query}").map do |attrs|
      # `attrs` is a Hash of user attributes sent in MS graph response.
      MicrosoftUser.new(attrs)
    end
  end
  # alias :get_all_users :users

  def users_photo(user)
    id = user.try(:microsoft_graph_id) || user.try(:id)
    get_raw("/users/#{id}/photo/$value")
  rescue RestClient::ResourceNotFound => e
    # seeing a 404 if user exists but there is no image
    # raise if the id is blank though whatever reason
    raise e if id.blank?
  end

  def manager(user)
    id = user.try(:microsoft_graph_id) || user.try(:id)
    response = get("/users/#{id}/manager")
    MicrosoftUser.new(response)
  rescue RestClient::ResourceNotFound => e
    # seeing a 404 if user exists but there is no image
    # raise if the id is blank though whatever reason
    raise e if id.blank?
  end

  def groups
    get_all_pages("/groups").map { |group| MicrosoftGroup.new(group) }
  end

  # Note: This API endpoint does not support client-side paginations (i.e. the $skip parameter)
  #       So here we use server-side pagination from the API with the provided skip_token
  # Also, the skip token will be nil for the first page request.
  def groups_with_skip_token(search_term: nil, skip_token: nil)
    params = {}
    params['$filter'] = "startswith(displayName,'#{search_term}')" if search_term.present?
    params['$skiptoken'] = skip_token if skip_token

    response = get('/groups', params)
    group_results = response['value'].map {|g| MicrosoftGroup.new(g) }
    next_link = response['@odata.nextLink']
    new_skip_token = CGI.parse(URI.parse(next_link).query)['$skiptoken'].first if next_link.present?

    [group_results, new_skip_token]
  end

  def group(id)
    MicrosoftGroup.new( get("/groups/#{id}") ).tap{|g| g.provider = "microsoft_graph"}
  end

  # Recursion Note:
  #   group_members gets members recursively as groups can have members that may be groups themselves
  #   Need to protect against circular references of groups
  #   Eg. a group that has a group as its member, and that subgroup has the parent group as its member
  #
  def group_members(group_id, found_group_ids = [], additional_attributes = [])
    select_query = select_query_for_attributes(USER_API_ATTRIBUTES + additional_attributes)
    members = get_all_pages("/groups/#{group_id}/members?#{select_query}")
                .map {|u| MicrosoftUser.new(u) }

    found_group_ids << group_id
    # recursively get members as some members may be groups themselves
    members = members.inject([]) do |set, member|
      if member.group?
        if found_group_ids.include?(member.id)
          Rails.logger.debug "Member: #{member.displayName} (#{member.id}) is a group that's already been retrieved - skipping..."
        else
          Rails.logger.debug "Member: #{member.displayName} (#{member.id}) is a group - going recursive..."
          set += group_members(member.id, found_group_ids, additional_attributes)
        end
      else
        Rails.logger.debug "Member: #{member.email} (#{member.id}) is a user, adding to the list..."
        set << member
      end
      # protect against weird 503 errors from MS :(
      # TODO: make this more robust to detect 503 and 429 and retry
      sleep 0.0001
      Rails.logger.debug "MGC: group_members sleeping"
      set
    end

    return members.uniq{|m| m.id }
  end

  def get_users_in_groups(groups, additional_attributes = [])
    users = []
    groups.each do |group|
      users += group_members(group.id, [], additional_attributes)
    end
    users.uniq
  end

  def get_all_pages(path, params = {}, headers = {})
    Rails.logger.debug "MGC: Getting all pages for #{path}"
    results = []
    counter = 0
    while((response = get(path, params, headers)) && (next_link = response['@odata.nextLink']) && (counter< 5000)) do
      Rails.logger.debug "MGC: response : #{response}"
      results << response["value"]
      Rails.logger.debug "MGC: results now: #{results.length}"
      Rails.logger.debug "MGC: page: #{next_link}"
      url = URI.parse(next_link)
      Rails.logger.debug "MGC: url: #{url}"
      Rails.logger.debug "MGC: query: #{url.query}"
      query_params = CGI.parse(url.query)
      Rails.logger.debug "MGC: query params object: #{query_params}"
      Rails.logger.debug "MGC: query params object: #{query_params.keys.map(&:class).join(',')}"
      skip_token = query_params["$skiptoken"].presence || query_params["$skipToken"].presence
      Rails.logger.debug "MGC: skip token: #{skip_token}"
      params["$skipToken"] = skip_token[0]
      Rails.logger.debug "MGC: params: #{params}"
      # protect against weird 503 errors from MS :(
      # TODO: make this more robust to detect 503 and 429 and retry
      sleep 0.5
      Rails.logger.debug "MGC: get_all_pages sleeping"
      counter += 1
    end
    results << response["value"]
    results.flatten
  end

  def get(path, params = {}, headers={})
    fpath = formatted_path(path)
    fheaders = formatted_headers(headers).merge(params: formatted_params(params))
    respond api.get(fpath, fheaders)

  rescue JSON::ParserError => e
    Rails.logger.debug "MGC: Caught GET exception (#{e.message}) on #{path} with #{params}"
    # ExceptionNotifier.notify_exception(e, data: { path: fpath, headers: fheaders })
    raise e
  end

  def post(path, params = {}, headers = {})
    fpath = formatted_path(path)
    fparams = formatted_params(params)
    fheaders = formatted_headers(headers)
    respond api.post(fpath, fparams, fheaders)
  rescue JSON::ParserError => e
    Rails.logger.debug "MGC: Caught POST exception (#{e.message}) on #{path} with #{params}"
    # ExceptionNotifier.notify_exception(e, data: { path: fpath, params: fparams, headers: fheaders })
    raise e
  end

  # PATCH here is for debugging at local console only
  # If we need it in the codebase, this should be more thoroughly looked at and implemented
  # def patch(path, params = {}, headers = {})
  #   fpath = formatted_path(path)
  #   fparams = formatted_params(params)
  #   fheaders = formatted_headers(headers)
  #   respond api.patch(fpath, fparams, fheaders)
  # rescue JSON::ParserError => e
  #   Rails.logger.debug "MGC: Caught PATCH exception (#{e.message}) on #{path} with #{params}"
  #   # ExceptionNotifier.notify_exception(e, data: { path: fpath, params: fparams, headers: fheaders })
  #   raise e
  # end

  private

  def default_params
    {}
  end

  def default_headers
    {Authorization: "Bearer #{api.token}"}
  end

  def formatted_headers(headers)
    default_headers.merge(headers)
  end

  def formatted_params(params)
    default_params.merge(params)
  end

  def formatted_path(path)
    BASE_URL+path
  end

  def get_raw(path, params = {}, headers={})
    api.get(formatted_path(path), formatted_headers(headers).merge(params: formatted_params(params)))
  end

  def respond(response)
    # Changing the semantic here.
    # Return the original object if its not a string that can be
    # json parsed. Objects up the stack can figure out what to do
    # or raise a more specific exception.
    # This handles the case when say an api request returns non-json
    # such as true or nil. The only thing this might have an effect on
    # is the #get and #post rescue clauses that rescue on a ParserError
    # exception. But those rescue clauses only log and re-raise.
    JSON.parse(response) rescue response
  end

  def select_query_for_attributes(attributes)
    { '$select' => attributes.reject(&:blank?).uniq.join(",") }.to_query
  end

  class MicrosoftUser < Hashie::Mash
    MS_DEFAULT_TIME = "0001-01-01T00:00:00Z"

    def first_name
      givenName
    end

    def last_name
      surname
    end

    def email
      mail
    end

    def start_date
      Time.parse(hireDate) if hireDate.present? && hireDate != MS_DEFAULT_TIME
    end

    def birthday
      self.class.parse_ms_graph_birthday(self[:birthday])
    end

    # sometimes members of a group may be group members
    def group?
      self["@odata.type"] == "#microsoft.graph.group"
    end

    def value_for_custom_field_mapping(cfm)
      if cfm.is_for_ms_graph_schema_extension?
        schema_extension_id = cfm.provider_key
        schema_extension_attribute_key = cfm.provider_attribute_key
        # Note: `schema_extension` is an object of MicrosoftUser - this is due to how Mash wraps the sub(nested) hashes.
        # In rare cases the `schema_extension_attribute_key` can have the same name as a method within this class. For
        # example - if schema_extension is #<MicrosoftGraphClient::MicrosoftUser first_name ="Larry">, then
        # `schema_extension.send(:first_name)` can call the method in this class giving us unintended result, whereas we
        # really want to call `schema_extension[:first_name]` to avoid surprises.
        schema_extension = self[schema_extension_id]
        schema_extension[schema_extension_attribute_key]
      else
        self.send(cfm.provider_key)
      end
    end

    def self.parse_ms_graph_birthday(birthday)
      return if birthday.blank? || birthday == MS_DEFAULT_TIME

      birthday = birthday.delete(" ")
      dashed_mm_dd_regex = %r{^\d{1,2}\-\d{1,2}$}
      if !!(birthday.match(dashed_mm_dd_regex))
        begin
          Time.strptime(birthday, '%m-%d')
        rescue ArgumentError => e
          Rails.logger.debug "Failed to parse birthday (#{birthday}) - #{e.message}"
          return
        end
      else
        Time.parse(birthday)
      end
    end
  end

  class MicrosoftGroup < Hashie::Mash
    def name
      displayName
    end

    def full_name
      displayName
    end
  end

  class RestClientWrapper
    attr_reader :token, :user

    def initialize(token, user)
      @token = token
      @user = user
    end

    def api_client
      RestClient
    end

    def authentication
      @authentication ||= user.authentications.microsoft_graph
    end

    def credentials
      @credentials ||= authentication.try(:credentials)
    end

    def refresh_token
      credentials["refresh_token"] rescue nil
    end

    def expires_at
      credentials["expires_at"] rescue nil
    end

    def expiry
      Time.at(expires_at) rescue nil
    end

    def get(*args)
      count = 0
      begin
        return api_client.get(*args)
      rescue RestClient::Unauthorized => e
        Rails.logger.debug "Caught unauthorized POST rest request - #{@user.id}-#{@user.email} - #{args}"
        # with refresh tokens, expiry can be nil, but token will still expire in a year, you can just refresh it
        if count == 0 && (expiry.nil? || token_expired?)
          count += 1
          begin
            Rails.logger.debug "Attempting refresh with count: #{count}"
            refresh!
            retry_request(:get, *args)
          rescue => e
            Rails.logger.debug "MGC: Caught GET exception (#{e.message}) - #{args} - #{@user.id}"
            # ExceptionNotifier.notify_exception(e, {data: {args: args[0], user: "#{@user.id}-#{@user.email}"}})
            raise e
          end
        else
          raise e
        end
      end
    end

    def post(*args)
      count = 0
      begin
        return api_client.post(*args)
      rescue RestClient::Unauthorized => e
        Rails.logger.debug "Caught unauthorized POST rest request - #{@user.id}-#{@user.email} - #{args}"
        # with refresh tokens, expiry can be nil, but token will still expire in a year, you can just refresh it
        if count == 0 && (expiry.nil? || token_expired?)
          count +=1
          begin
            Rails.logger.debug "Attempting refresh with count: #{count}"
            refresh!
            retry_request(:post, *args)
          rescue => e
            Rails.logger.debug "MGC: Caught POST exception (#{e.message}) - #{args}"
            # ExceptionNotifier.notify_exception(e, {data: {args: args}})
          end
          retry
        else
          raise e
        end
      end
    end

  # PATCH here is for debugging at local console only
  # If we need it in the codebase, this should be more thoroughly looked at and implemented
    # def patch(*args)
    #   count = 0
    #   begin
    #     return api_client.patch(*args)
    #   rescue RestClient::Unauthorized => e
    #     Rails.logger.debug "Caught unauthorized PATCH rest request - #{@user.id}-#{@user.email} - #{args}"
    #     # with refresh tokens, expiry can be nil, but token will still expire in a year, you can just refresh it
    #     if count == 0 && (expiry.nil? || token_expired?)
    #       count +=1
    #       begin
    #         Rails.logger.debug "Attempting refresh with count: #{count}"
    #         refresh!
    #         retry_request(:patch, *args)
    #       rescue => e
    #         Rails.logger.debug "MGC: Caught PATCH exception (#{e.message}) - #{args}"
    #         # ExceptionNotifier.notify_exception(e, {data: {args: args}})
    #       end
    #       retry
    #     else
    #       raise e
    #     end
    #   end
    # end

    def refresh!
      Rails.logger.debug "Refreshing microsoft_graph token - #{@user.id}-#{@user.email}"
      Rails.logger.debug "Refreshing microsoft_graph token2 - #{@token}"
      # if token_expired?
        response    = RestClient.post "https://login.microsoftonline.com/common/oauth2/v2.0/token",
          :grant_type => 'refresh_token',
          :refresh_token => refresh_token,
          :client_id => Recognize::Application.config.rCreds['o365']['client_id'],
          :client_secret => Recognize::Application.config.rCreds['o365']['secret']

        Rails.logger.debug "response: #{response}"

        refresh_hash = JSON.parse(response.body)

        Rails.logger.debug "refresh hash: #{refresh_hash}"

        authentication.credentials["token"] = refresh_hash["access_token"]
        authentication.credentials["expires_at"] = refresh_hash["expires_on"]
        authentication.credentials["refresh_token"] = refresh_hash["refresh_token"]

        Rails.logger.debug "updating authentication: #{authentication.inspect}"
        authentication.save

        @token = authentication.credentials["token"]

      # end
    rescue => e
      Rails.logger.debug "MGC: Caught exception trying to refresh token (#{e.message})"

    end

    def retry_request(type, *args)
      args[1][:Authorization] = "Bearer #{@token}"
      api_client.send(type, *args)
    end

    def token_expired?
      return false if expiry.nil?
      return true if expiry < Time.now # expired token, so we should quickly return
    end
  end
end
