# frozen_string_literal: true

class Cms::IntegrationsController < Cms::BaseController
  cms_action :index, :show
    
  def index
    @categories = wp_client.integration_categories
  end

  def show
    @post = wp_client.get_post_by_slug(params[:slug])

    if @post.blank?
      render file: "#{Rails.root}/public/404", status: :not_found
    end
  end
end
