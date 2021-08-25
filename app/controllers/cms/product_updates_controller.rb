# frozen_string_literal: true

class Cms::ProductUpdatesController < Cms::BaseController
  cms_action :index

  def index
    @product_updates = wp_client.product_update_posts
  end
end
