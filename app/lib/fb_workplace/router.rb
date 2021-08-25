class FbWorkplace::Router
  attr_reader :app, :env, :request, :uuid

  ROUTES = {
    # There used ot be multiple routes here...
    "/fb_workplace/webhook" => :receive_hook,
    "/fb_workplace/deauth" => :receive_hook
  }

  def self.route_for(action)
    ROUTES.key(action)
  end

  def initialize(app, env)
    @app = app
    @env = env
    @request = Rack::Request.new(env)
    @uuid = SecureRandom.uuid
  end

  def call
    log "#{route_method} - #{request.path_info} - #{request.params}"
    send(route_method)
  rescue Exception => e
    log "failed: #{route_method.inspect}"
    log "#{e.message}"
    log "#{e.backtrace.join("\n")}"
    ExceptionNotifier.notify_exception(e, data: {request: route_method})

    # always return success response, otherwise FB will keep trying
    success_response
    # [500, {"Content-Type" => "text/plain"}, [e.message]]
  end

  def log(msg)
    FbWorkplace::Logger.log(msg, uuid: uuid)
  end

  def matches_route?
    route_method.present?
  end

  def not_authorized
    [401, {"Content-Type" => "text/plain"}, "Not Authorized"]
  end

  def receive_hook
    if request.get? || request.params['hub.verify_token'].present?
      receive_hook_subscription
    else
      receive_hook_post
    end
  end

  def receive_hook_subscription
    verify_token = Recognize::Application.config.rCreds['fb_workplace']['verify_token']
    if request.params['hub.verify_token'] == verify_token
      [200, {"Content-Type" => "text/plain"}, [request.params['hub.challenge']]]
    else
      not_authorized
    end
  end

  def receive_hook_post
    body = request.body.read
    post_params  = HashWithIndifferentAccess.new(JSON.parse(body))
    log("#############-Start Hook Post-####################")
    log(post_params)

    if duplicate_request?(post_params)
      log("#############-End Hook Post-####################")
      return [200, {"Content-Type" => "text/plain"}, ["Success"]]
    end


    # A hook has many entries
    # Each entry has many changes
    # A change might be an @mention
    # Each change should support a #call method to handle itself
    #


    hook = FbWorkplace::Webhook.factory(post_params, request_uuid: uuid)
    results = []

    if hook.present? && hook.entries.size > 0
      hook.entries.each do |entry|

        entry.changes.each do |change|
          begin
            if change.acceptable?
              results << change.call
            else
              log "Change rejected: #{change.webhook.payload}"
            end
          end
        end

        entry.messages.each do |message|
          begin
            if message.acceptable?
              results << message.call
            else
              log "Message rejected: #{message.webhook.payload}"
            end
          end
        end
      end
    end


    # Typically there are really only one entry(change or message) in a payload, but due
    # to fb's structure, we anticipate the potential for more than one
    # But raise an exception if it occurs to bring to our attention to more properly handle

    if results.length > 1
      raise "More than 1 result in Workplace webhook"
    elsif results[0].kind_of?(Hash) && results[0].has_key?(:payload)
      result = results[0]
      result = [result[:status], result[:headers], result[:payload]]
    else
      result = [200, {"Content-Type" => "text/plain"}, ["Success"]]
    end
    log "Returning result from hook: #{result}"
    log("#############-End Hook Post-####################")
    return result
  end

  def route_method
    @route_method ||= ROUTES[env['PATH_INFO']]
  end

  def success_response(msg = "Success")
    [200, {"Content-Type" => "text/plain"}, [msg]]
  end

  private
  def duplicate_request?(params)
    # Not all hooks have a message id (mid)
    # Use mid when its there, otherwise, try to de-dupe by md5 of the request body
    duplicate_by_mid?(params) || duplicate_by_md5?(params)
  end

  def duplicate_by_mid?(params)
    message_id = params[:entry][0][:messaging][0][:message][:mid] rescue nil
    return false unless message_id.present?

    return duplicate_by_key?(params, "mid-#{message_id}")
  end

  def duplicate_by_md5?(params)
    request_body_md5 = Digest::MD5.hexdigest(params.to_json)
    return duplicate_by_key?(params, "md5-#{request_body_md5}")

  end

  def duplicate_by_key?(params, key)
    request_key = "FbWorkplace-request-#{key}"
    log(request_key)

    if Rails.cache.exist?(request_key)
      log('*** Caught duplicate request ***')
      return true
    end
    log("Writing to cache: #{request_key}")
    Rails.cache.write(request_key, true, expires_in: 15.minutes)

    return false
  end
end
