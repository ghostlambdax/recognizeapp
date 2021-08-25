# frozen_string_literal: true
#
# Wordpress hierarchy
  # categories
  #   feature_categories
  #   integration_categories
  # posts
  #   resources
  #   articles
  #   videos
  #   product_update_posts
  #   feature_posts
  #   homepage_content
  # tags

class WordpressClient
  DEFAULT_API_BASE = "https://cms.recognizeapp.com"
  WP_API_BASE = "/wp-json/wp/v2"
  WP_REST_POSTS_BASE = "/wp-json/acf/v3/posts"
  WP_REST_ROUTE_BASE = "?rest_route="
  TAGS_BASE = '/tags'
  # WP_ACF_POSTS_BASE = "/acf/v3/posts" # unused as we can get ACF from rest api now, but leaving in case we need it later

  def accessible?
    # convenience method to check if wordpress is accessible
    # if we don't have this, the connection will take a long time to timeout
    timeout = 5 #seconds
    RestClient::Request.execute(:method => :head, :url => cms_host, :timeout => timeout)
    return true
  rescue RestClient::Exceptions::OpenTimeout => e
    Rails.logger.debug "Could not connect to wordpress within #{timeout} seconds - Are you connected to the VPN?"
    return false
  end

  def categories
    wp_api_get("/categories?per_page=30")
  end

  def resources
    posts_for_category(38)
  end

  def articles
    posts_for_category(26)
  end

  def videos
    posts_for_category(37)
  end

  def feature_categories
    Cms::Category.collection(wp_api_get(category_path_with_parent(1)))
  end

  def integration_categories
    Cms::Category.collection(wp_api_get(category_path_with_parent(2)))
  end

  def product_update_posts
    posts_for_category(29)
  end

  def feature_posts
    posts_for_category(1)
  end

  def homepage_content
    posts_for_category(28).first
  end

  def cms_host
    # host should have scheme with it, so https://cms.recognizeapp.com
    @cms_host ||= (Recognize::Application.config.rCreds.dig("cms", "host") || DEFAULT_API_BASE)
  end

  def get_post(post_id)
    Cms::Post.new( wp_api_get("/posts/#{post_id}"))
  end

  def get_post_by_slug(slug)
    # Do a `detect` here because there may be other slugs that have this shorter
    # slug as a substring. The api request could return these other results
    # so pick the one that is the exact match
    Cms::Post.new(wp_api_get("/posts?slug=#{slug}").detect { |post| post['slug'] == slug })
  end

  def get_tags_by_post(post_id)
    Cms::Tag.collection(wp_api_get("#{TAGS_BASE}?post=#{post_id}"))
  end

  def get_posts_by_tag(tag_id)
    Cms::Post.collection(get("#{WP_REST_POSTS_BASE}?tags=#{tag_id}"))
  end

  def get_tag(tag_id)
    Cms::Tag.new(wp_api_get("#{TAGS_BASE}/#{tag_id}"))
  end

  def get(path)
    url = full_path(path)
    log "Getting: #{url}"
    JSON.parse(RestClient.get(url), { object_class: OpenStruct })
  end

  def posts_for_category(category_id)
    Cms::Post.collection(wp_api_get("/posts?categories=#{category_id}"))
  end

  def wp_api_get(path)
    get(join_uri_fragments(WP_API_BASE,path))
  end

  private
  def log(msg)
    Rails.logger.debug msg
  end

  def category_path_with_parent(id)
    "/categories?per_page=30&parent=#{id}"
  end

  def full_path(path)
    uri = Addressable::URI.parse(cms_host)
    uri.path = path
    uri.to_s
  end

  def join_uri_fragments(*fragments)
    File.join(*fragments.map(&:to_s))
  end
end
