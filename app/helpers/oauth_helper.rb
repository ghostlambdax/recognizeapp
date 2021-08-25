module OauthHelper
  def auth_method_title(provider)
    case provider.to_sym
    when :google_oauth2
      "Google"
    when :yammer
      "Yammer"
    when :microsoft_graph
      "Microsoft / Office365"
    end
  end
end
