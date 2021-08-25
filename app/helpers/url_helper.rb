module UrlHelper
  # url string
  # params hash
  def add_params_to_url(url, params)
    uri = URI.parse(url)
    params.each do |k, v|
      new_query_ar = URI.decode_www_form(String(uri.query)) << [k, v]
      uri.query = URI.encode_www_form(new_query_ar)
    end
    uri.to_s
  end
end
