class Middleware::Autocompleter
  def initialize(app)
    @app = app
  end

  def call(env)
    # Rails.logger.debug "[Autocompleter] - #{env['PATH_INFO']}" unless env['PATH_INFO'].match(/\/assets/) || env['PATH_INFO'].match(/\/uploads/)
    if env['PATH_INFO'] == "/coworkers"
      autocomplete(env)
    else
      @app.call(env)
    end
  end

  def not_authorized
    [401, {"Content-Type" => "text/plain"}, "Not Authorized"]
  end

  private
  def autocomplete(env)
    request = Rack::Request.new(env)

    return not_authorized if request.cookies.nil?

    unless Rails.configuration.host == "recognizeapp.com"
      session_key = "#{Recognize::Application.config.session_options[:key]}"
    else
      session_key = "_session_id"
    end

    sid = Rack::Session::SessionId.new( request.cookies[session_key] )
    session = ActiveRecord::SessionStore::Session.find_by_session_id( sid.private_id )
    if session
      user = User.find(session.data['user_credentials_id'])

      term, limit, dept, network =
          request.params["term"], request.params["limit"], request.params["dept"], request.params["network"]
      include_self = !!request.params["include_self"]
      Rails.logger.debug "[Autocompleter] - term: #{term}"

      if dept.present? && user.director?
        # handle searching for users when dept is present and user is director
        search_user = get_search_user(Company.where(domain: dept).first)
      elsif network.present? && user.admin?
        # handle searching for users when network is present and user is admin
        search_user = get_search_user(Company.where(domain: network).first)
      else
        search_user = user
      end

      list = search_user.coworkers(term, limit: limit, include_self: include_self)
      list = list[0..limit[1].to_i] if limit && limit[1]
      [200, {"Content-Type" => "text/plain"}, [list.to_json]]
    else
      return not_authorized
    end
  rescue Exception => e
    Rails.logger.warn "[Autocompleter] failed autocomplete request: #{request.fullpath}" rescue nil
    Rails.logger.debug "[Autocompleter] #{e.message}"
    Rails.logger.debug "[Autocompleter] #{e.backtrace.join("\n")}"
    ExceptionNotifier.notify_exception(e, data: {request: request})
    [500, {"Content-Type" => "text/plain"}, [e.message]]
  end

  def get_search_user(company)
    # just use first company admin to search
    company.company_admin || company.users.first
  end
end
