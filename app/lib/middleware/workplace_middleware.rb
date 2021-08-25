module Middleware
  # require_dependency File.join(Rails.root, 'lib/fb_workplace')
  require_relative '../fb_workplace'
  require_relative '../fb_workplace/router'
  class WorkplaceMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      start_time = Time.current
      router = FbWorkplace::Router.new(@app, env)

      if router.matches_route?
        response = router.call
        router.log "Returning response in #{Time.current - start_time}ms"
        response
      else
        @app.call(env)
      end
    end

  end
end


  # def not_authorized
  #   [401, {"Content-Type" => "text/plain"}, "Not Authorized"]
  # end

  # private
  # def install(env)
  # end

  # def user(env)
  #   @user ||= begin
  #     request = Rack::Request.new(env)

  #     return not_authorized if request.cookies.nil?

  #     unless Rails.configuration.host == "recognizeapp.com"
  #       session_key = "#{Recognize::Application.config.session_options[:key]}"
  #     else
  #       session_key = "_session_id"
  #     end

  #     session = ActiveRecord::SessionStore::Session.find_by_session_id(request.cookies[session_key])
  #     if session
  #       User.find(session.data['user_credentials_id'])
  #     else
  #       User.new # pass back stubbed object so we can memo-ize @user
  #     end
  #   end
  # end

  # def autocomplete(env)
  #   request = Rack::Request.new(env)

  #   return not_authorized if request.cookies.nil?

  #   unless Rails.configuration.host == "recognizeapp.com"
  #     session_key = "#{Recognize::Application.config.session_options[:key]}"
  #   else
  #     session_key = "_session_id"
  #   end

  #   session = ActiveRecord::SessionStore::Session.find_by_session_id(request.cookies[session_key])
  #   if session
  #     user = User.find(session.data['user_credentials_id'])

  #     term, limit, dept = request.params["term"], request.params["limit"], request.params["dept"]
  #     include_self = !!request.params["include_self"]
  #     Rails.logger.debug "[Autocompleter] - term: #{term}"

  #     # handle searching for users when dept is present and user is director
  #     if dept.present? && user.director?
  #       # just use first company admin to search
  #       company = Company.where(domain: dept).first
  #       search_user = company.company_admin || company.users.first
  #       list = search_user.coworkers(term, limit: limit, include_self: include_self)

  #     else
  #       list = user.coworkers(term, limit: limit, include_self: include_self)
  #     end

  #     list = list[0..limit[1].to_i] if limit && limit[1]
  #     [200, {"Content-Type" => "text/plain"}, [list.to_json]]
  #   else
  #     return not_authorized
  #   end
  # rescue Exception => e
  #   Rails.logger.warn "[Autocompleter] failed autocomplete request: #{request.inspect}"
  #   Rails.logger.debug "[Autocompleter] #{e.message}"
  #   Rails.logger.debug "[Autocompleter] #{e.backtrace.join("\n")}"
  #   ExceptionNotifier.notify_exception(e, data: {request: request})
  #   [500, {"Content-Type" => "text/plain"}, [e.message]]
  # end
# end
