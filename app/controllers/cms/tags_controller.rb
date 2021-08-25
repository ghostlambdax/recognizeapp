# frozen_string_literal: true

class Cms::TagsController < Cms::BaseController
  cms_action :show

  def show
    @tag = wp_client.get_tag(params[:id])
    @posts = wp_client.get_posts_by_tag(params[:id])

    if @posts.blank?
      render file: "#{Rails.root}/public/404", status: :not_found
    end
  end
end
