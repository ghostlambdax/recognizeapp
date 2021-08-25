# frozen_string_literal: true

class Cms::FeaturesController < Cms::BaseController
  cms_action :show
  
  def show
    @post = wp_client.get_post_by_slug(params[:slug])

    if @post.blank?
      render file: "#{Rails.root}/public/404", status: :not_found
    end
  end
end
