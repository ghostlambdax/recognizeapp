module CmsConcern
  extend ActiveSupport::Concern

  included do
    helper_method :wp_client
  end

  module ClassMethods
    def cms_action(*cms_actions)
      @cms_actions = cms_actions
      before_action :ensure_cms_host, only: cms_actions
      caches_page *cms_actions, gzip: true, unless: :skip_cache?
    end

    def cms_actions
      @cms_actions
    end
  end

  private
  def ensure_cms_host
    raise "Cannot connect to #{Recognize::Application.config.wp_client.cms_host}. This controller will not load. Are you connected to the VPN?" unless Recognize::Application.config.wp_client.accessible?
  end

  # This will only work if we don't have a cache and don't want to populate one
  # Once the page cache is populated, the requests will be served by the webserver
  # and never hit rails and thus this callback
  def skip_cache?
    # Only cache production and staging environments
    # Leaving QA environments so that writers can quickly see their updates
    # And admins can approve them and bust the cache in production
    # This conditional also allows non-prod environments to test caching
    # NOTE: turn on/off development mode caching with `rake dev:cache`
    if !Rails.env.production? || ['recognizeapp.com', 'demo.recognizeapp.com'].any?{|host| Recognize::Application.config.host == host}
      # so if production or staging, check the query parameter
      ['off', false, 'false', 'no'].any?{ |off| params[:cache].to_s == off.to_s }
    else
      # Here, we're a QA server and therefore should skip cache
      return true
    end
  end

  def wp_client
    @wp_client ||= Recognize::Application.config.wp_client
  end
end
