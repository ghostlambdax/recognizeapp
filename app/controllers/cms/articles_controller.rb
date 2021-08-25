# frozen_string_literal: true
class Cms::ArticlesController < Cms::BaseController
  layout 'article'
  before_action :common_setup

  cms_action :show
  def show
    @article_canonical = cms_article_url(slug: params[:slug])
    @post = wp_client.get_post_by_slug(params[:slug])
    # @tags = wp_client.get_tags_by_post(params[:id]) Removed for now until move to slug

    if @post&.data.blank?
      render file: "#{Rails.root}/public/404", status: :not_found
    end
  end


  private

  def common_setup
    @use_marketing_manifest = true
  end
end
