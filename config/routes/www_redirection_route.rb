class RedirectWwwConstraint
  def matches?(request)
    # don't match on any logged in route
    return false if request.session.key?("user_credentials")

    paths_to_skip = [/^\/api/, /^\/rack_session/, /^\/auth\//]
    will_redirect = request.host.match(/^www\./i) && paths_to_skip.none?{|path| request.path.match(path)}
    will_redirect
  end
end

# selectively redirect www sub-domain requests to non-www for SEO
# originally from: https://stackoverflow.com/a/31994270
#
constraints(RedirectWwwConstraint.new) do
  match '(*any)', via: :get, to: redirect { |_params, request|
    # parse the current request url to strip out 'www.'
    URI.parse(request.url).tap { |uri| uri.host.sub!(/^www\./i, '') }.to_s
  }
end
